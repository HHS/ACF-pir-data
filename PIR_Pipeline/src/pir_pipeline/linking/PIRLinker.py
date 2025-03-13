"""Class for ingesting and linking PIR data"""

import hashlib
import os
from typing import Self

import numpy as np
import pandas as pd
from fuzzywuzzy import fuzz

from pir_pipeline.config import db_config
from pir_pipeline.utils import SQLAlchemyUtils


class PIRLinker:
    def __init__(self, records: list[tuple] | list[dict], sql: SQLAlchemyUtils):
        """Initialize a PIRIngestor object

        Args:
            workbook (str|os.PathLike): File path to an Excel Workbook
        """
        self._data = pd.DataFrame.from_records(records)
        self._data = self._data[~self._data["question_id"].duplicated()]
        self._sql = sql
        self.get_question_data()

    def get_question_data(self) -> Self:
        """Select distinct questions from the question table

        Returns:
            Self: PIRIngestor object
        """
        question_columns = self._sql.get_columns(
            "question",
            "AND (column_name NOT IN ('subsection', 'category'))",
        )
        question_columns = ",".join(question_columns)
        self._question = self._sql.get_records(
            f"SELECT {question_columns} FROM question",
        )

        return self

    def link(self) -> Self:
        """Create links between existing questions and newly ingested questions

        Returns:
            Self: PIRIngestor object
        """

        # Look for a direct match on question_id
        df = self._data.copy()
        df = df.merge(
            self._question[["question_id", "uqid", "year"]].drop_duplicates(),
            how="left",
            on="question_id",
            validate="many_to_many",
            indicator=True,
        )
        df = df[df["year_x"] != df["year_y"]]

        df = df[~df["question_id"].duplicated()]
        df.rename(columns={"year_x": "year"}, inplace=True)
        df["uqid"] = df["uqid_x"].combine_first(df["uqid_y"])

        self._linked = df[df["_merge"] == "both"].drop(
            columns=["uqid_x", "uqid_y", "year_y", "_merge"]
        )
        self._linked["linked_id"] = self._linked["question_id"]

        # Get unlinked by self._data.anti_join(linked)
        self._unlinked = self._data.merge(
            self._linked[["question_id"]], how="left", on="question_id", indicator=True
        )
        self._unlinked = self._unlinked[self._unlinked["_merge"] == "left_only"].drop(
            columns="_merge"
        )

        assert not self._linked.duplicated(["question_id"]).any()
        assert (
            self._data[~self._data["question_id"].duplicated()].shape[0]
            - self._linked.shape[0]
            == self._unlinked.shape[0]
        )

        # Look for a fuzzy match on question_name, question_number, or question_text
        self._cross = self._unlinked.merge(
            self._question,
            how="left",
            on=["question_type", "section"],
            validate="many_to_many",
        )
        self._cross = self._cross[self._cross["year_x"] != self._cross["year_y"]]
        if not self._cross.empty:
            self.fuzzy_link()

        self.prepare_for_insertion()

        return self

    def fuzzy_link(self) -> Self:
        """Link questions using Levenshtein algorithm

        Returns:
            Self: PIRIngestor object
        """

        def confirm_link(row: pd.Series):
            scores = [item == 100 for item in row.filter(like="score")]
            return sum(scores) >= 2

        # Add similarity score variables
        for column in ["question_name", "question_number", "question_text"]:
            y = f"{column}_y"
            x = f"{column}_x"
            score = f"{column}_score"
            for var in [x, y]:
                self._cross[var] = self._cross[var].fillna("")

            self._cross[score] = self._cross[[x, y]].apply(
                lambda row: fuzz.ratio(row[x], row[y]), axis=1
            )

        # Determine whether score meets threshold for match
        self._cross["confirmed"] = self._cross.filter(regex="score|section|type").apply(
            confirm_link, axis=1
        )
        self._cross["combined_score"] = self._cross.filter(like="score").sum(axis=1)

        confirmed = self._cross[self._cross["confirmed"]].copy()

        # In the event of duplicates, choose the record with the highest combined score
        confirmed = (
            confirmed.sort_values(["question_id_x", "combined_score"])
            .groupby(["question_id_x"])
            .sample(1)
        )

        # Truncate confirmed data frame
        confirmed["question_id"], confirmed["linked_id"] = (
            confirmed["question_id_x"],
            confirmed["question_id_y"],
        )
        confirmed["uqid"] = confirmed["uqid_x"].combine_first(confirmed["uqid_y"])
        confirmed = confirmed[["question_id", "linked_id", "uqid"]]

        # Update linked and unlinked
        df = self._unlinked.merge(
            confirmed, how="left", on="question_id", indicator=True
        )
        df["uqid"] = df["uqid_x"].combine_first(df["uqid_y"])
        df.drop(columns=["uqid_x", "uqid_y"], inplace=True)

        linked = df[df["_merge"] == "both"].drop(columns="_merge")
        assert linked["uqid"].all()
        unlinked = df[df["_merge"] == "left_only"].drop(columns="_merge")
        assert not unlinked["uqid"].any()

        assert not self._linked.duplicated(["question_id"]).any()
        self._linked = pd.concat([self._linked, linked])
        assert not self._linked.duplicated(["question_id"]).any()
        self._unlinked = unlinked

        del self._cross

        return self

    def prepare_for_insertion(self) -> Self:
        """Prepare question data for final insertion

        Also, prepare to update any newly linked extant records as necessary.

        Returns:
            Self: PIRIngestor object
        """
        df = self._data
        df = df.merge(
            self._linked[["question_id", "linked_id", "uqid"]],
            how="left",
            on="question_id",
        )
        assert self._linked.shape[0] == df["linked_id"].notna().sum()
        assert self._unlinked.shape[0] == df["linked_id"].isna().sum()

        del self._linked
        del self._unlinked

        df["uqid"] = df["uqid_x"].combine_first(df["uqid_y"])
        df["uqid"] = df.apply(lambda row: self.gen_uqid(row), axis=1)
        df.drop(columns=["uqid_x", "uqid_y"], inplace=True)

        self._data = df
        self.update_unlinked()
        self._data["question"] = self._data["question"][
            self._sql._schemas["question"]["Field"]
        ]

        return self

    def gen_uqid(self, row: pd.Series) -> str | float:
        """Generate a unique question ID

        Args:
            row (pd.Series): Pandas series containing row information

        Returns:
            str | float: A null value or a hashed question ID returned as a string
        """
        if isinstance(row["uqid"], str) and row["uqid"]:
            return row["uqid"]

        if not isinstance(row["linked_id"], str):
            assert np.isnan(
                row["linked_id"]
            ), f"Unexpected value of linked_id: {row["linked_id"]}"
            return row["linked_id"]

        return hashlib.md5(row["linked_id"].encode()).hexdigest()

    def update_unlinked(self) -> Self:
        """Find any unlinked records that should be updated with a new uqid

        Returns:
            Self: PIRIngestor object
        """

        # Get the unlinked records
        unlinked = self._sql.get_records("SELECT DISTINCT question_id FROM unlinked")

        # Check whether unlinked records are among those to link currently
        # No need to worry about setting an ID to null, because if an ID in unlinked
        # matches, then there must be a uqid in self._data["question"]
        unlinked = unlinked.merge(
            self._data["question"][["linked_id", "uqid"]],
            how="inner",
            left_on="question_id",
            right_on="linked_id",
        )

        self._unlinked = unlinked

        return self


if __name__ == "__main__":
    sql_alchemy = SQLAlchemyUtils(**db_config, database="pir")
    records = sql_alchemy.get_records("SELECT * FROM question LIMIT 10").to_dict(
        orient="records"
    )

    PIRLinker(records, sql_alchemy).link()
