"""Class for linking PIR data"""

import hashlib
from typing import Self

import numpy as np
import pandas as pd
from fuzzywuzzy import fuzz
from sqlalchemy import bindparam

from pir_pipeline.config import DB_CONFIG
from pir_pipeline.utils.SQLAlchemyUtils import SQLAlchemyUtils
from pir_pipeline.utils.utils import get_logger


class PIRLinker:
    def __init__(self, records: list[dict] | pd.DataFrame, sql: SQLAlchemyUtils):
        """Instantiate instance of PIRLinker object

        Args:
            records (list[tuple] | list[dict]): Records to link
            sql (SQLAlchemyUtils): A SQLAlchemyUtils object for interacting with the database
        """

        self._logger = get_logger(__name__)

        invalid_type = None
        if isinstance(records, pd.DataFrame):
            self._data = records
        elif isinstance(records, list):
            if not all([isinstance(record, dict) for record in records]):
                invalid_type = True
            self._data = pd.DataFrame.from_records(records)
        else:
            invalid_type = True

        if invalid_type:
            raise TypeError("records should be of type list[dict] or pd.DataFrame")

        if "question_id" in self._data.columns:
            self._data = self._data[~self._data["question_id"].duplicated()]
            self._unique_question_id = "question_id"
        else:
            self._unique_question_id = "uqid"

        self._sql = sql

        self._logger.info("Initialized linker.")

    def get_question_data(self, which: str = "all") -> Self:
        """Get data from the question table

        Args:
            which (str): which can be used to specify what data is returned from the question table. \
            Options include 'all', 'linked', and 'unlinked' which return data from the \
            full question table, linked view, and unlinked view respectively. A custom \
            query can also be specified using the which argument.

        Returns:
            Self: PIRLinker object
        """

        if which == "all":
            self._question = self._sql.get_records("question")
            self._question = self._question.drop(columns=["category", "subsection"])
        elif which == "linked":
            self._question = self._sql.get_records("linked")
        elif which == "unlinked":
            self._question = self._sql.get_records("unlinked")
        else:
            self._question = self._sql.get_records(which)

        self._logger.info("Obtained question data.")

        return self

    def question_data_check(self):
        """Check for question data and get it if not present"""

        try:
            self._question
        except AttributeError:
            self.get_question_data()

    def link(self) -> Self:
        """Attempt to link records provided to records in the database.

        Returns:
            Self: PIRLinker object
        """

        self.question_data_check()

        try:
            self._question_columns
        except AttributeError:
            self._question_columns = self._sql.get_columns("question")

        # Look for a direct match on question_id
        self.direct_link()

        # Look for a fuzzy match on question_name, question_number, or question_text
        self.join_on_type_and_section("unlinked")
        if not self._cross.empty:
            self.fuzzy_link()

        self.prepare_for_insertion()

        return self

    def consolidate_uqids(self) -> Self:
        df = self._data
        unique_columns = ["question_name", "question_text", "section", "question_type"]
        modal_uqid = (
            df[df["uqid"].notna()]
            .groupby(unique_columns)[["uqid"]]
            .apply(lambda x: x.mode())
            .reset_index()
        )
        modal_uqid = modal_uqid[~modal_uqid[unique_columns].duplicated()]
        df = df.merge(modal_uqid, how="left", on=unique_columns, validate="many_to_one")

        df["uqid"] = df["uqid_y"].combine_first(df["uqid_x"])
        df.drop(columns=["uqid_x", "uqid_y"], inplace=True)

        df.replace({np.nan: None}, inplace=True)
        self._data = df
        self._data = self._data[self._question_columns]

    def direct_link(self) -> Self:
        """Make a direct link on question_id

        Returns:
            Self: PIRLinker Object
        """

        self.question_data_check()

        df = self._data.copy()
        df = df.merge(
            self._question[["question_id", "uqid", "year"]].drop_duplicates(),
            how="left",
            on="question_id",
            validate="many_to_many",
            indicator=True,
        )
        df = df[df["year_x"] != df["year_y"]]  # Do not match with self

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

        assert not self._linked.duplicated(["question_id"]).any(), self._logger.error(
            "Some question_ids are duplicated."
        )
        assert (
            self._data[~self._data["question_id"].duplicated()].shape[0]
            - self._linked.shape[0]
            == self._unlinked.shape[0]
        ), self._logger.error(
            "Unique question_ids in data - unique question_ids in linked != unique question_ids in unlinked"
        )

        self._logger.info("Made links on question_id.")

        return self

    def join_on_type_and_section(self, which: str):
        """Execute many-to-many join on type and section

        Args:
            which (str): Which dataset should be the left-hand side of the join? Options \
            include 'unlinked' and 'data'.

        Returns:
            Self: PIRLinker object
        """

        self._cross: pd.DataFrame
        if which == "unlinked":
            df = self._unlinked.copy()
        elif which == "data":
            df = self._data.copy()
            self._original_columns = self._data.columns.tolist()

        unique_ids = set(df[self._unique_question_id].unique())
        missing_section = set(
            df[df["section"].isna()][self._unique_question_id].unique()
        )

        # Many-to-many merge on question type and section to enable checking all potential
        # matches
        df = df.merge(
            self._question,
            how="left",
            on=["question_type", "section"],
            validate="many_to_many",
        )

        # Drop cases where year is equal or uqid is equal
        if self._unique_question_id == "question_id" and not df.empty:
            self._cross = df[df["year_x"] != df["year_y"]]

            if self._cross["uqid_x"].unique().tolist()[0] is not None:
                self._cross = self._cross[
                    self._cross["uqid_x"] != self._cross["uqid_y"]
                ]
        else:
            self._cross = df[df["uqid_x"] != df["uqid_y"]]

        # Remove cases where unique_question_id combination is duplicated
        if len(unique_ids) == 1:
            for ident in ["question_id", "uqid"]:
                self._cross = self._cross[
                    ~self._cross[[f"{ident}_x", f"{ident}_y"]].duplicated()
                ]
        else:
            self._cross = self._cross[
                ~self._cross[
                    [f"{self._unique_question_id}_x", f"{self._unique_question_id}_y"]
                ].duplicated()
            ]

        # Check that the cross join has every unique ID that isn't missing a section
        cross_unique_ids = set(self._cross[f"{self._unique_question_id}_x"].unique())
        assert (
            cross_unique_ids.union(missing_section) == unique_ids
        ), self._logger.error("Some IDs were lost")

        return self

    def fuzzy_link(self, num_matches: int = None) -> Self | pd.DataFrame:
        """Link questions using a Levenshtein algorithm

        Args:
            num_matches (int, optional): Number of potential matches to return. Defaults to None.

        Returns:
            Self | pd.DataFrame: PIRLinker object or a dataframe containing potential matches.
        """

        def confirm_link(row: pd.Series):
            scores = [item == 100 for item in row.filter(like="score")]
            return sum(scores) >= 2

        self.question_data_check()

        try:
            self._question
        except AttributeError:
            self.get_question_data()

        try:
            self._cross
        except AttributeError:
            assert (
                num_matches is not None
                and num_matches > 0
                and isinstance(num_matches, int)
            ), self._logger.error(
                f"Number of matches should be an integer greater than 0, not {num_matches}"
            )
            self.join_on_type_and_section("data")

        # Add similarity score variables
        for column in ["question_name", "question_number", "question_text"]:
            y = f"{column}_y"
            x = f"{column}_x"
            score = f"{column}_score"
            for var in [x, y]:
                self._cross.loc[:, var] = self._cross[var].fillna("")

            self._cross[score] = self._cross[[x, y]].apply(
                lambda row: fuzz.ratio(row[x], row[y]), axis=1
            )

        # Sum similarity score
        self._cross["combined_score"] = self._cross.filter(like="score").sum(axis=1)

        # If a number of matches is specified, get that number of matches and return
        # the resultant dataframe
        if num_matches:
            matches = (
                self._cross.sort_values(
                    [f"{self._unique_question_id}_x", "combined_score"], ascending=False
                )
                .groupby([f"{self._unique_question_id}_x"])
                .head(num_matches)
            )
            drop_columns = matches.filter(regex="(_x|_score)$").columns
            matches.drop(columns=drop_columns, inplace=True)
            matches.rename(columns=lambda col: col.replace("_y", ""), inplace=True)

            return matches[self._original_columns]

        # Determine whether score meets threshold for match
        self._cross["confirmed"] = self._cross.filter(regex="score|section|type").apply(
            confirm_link, axis=1
        )
        confirmed = self._cross[self._cross["confirmed"]].copy()

        # In the event of duplicates, choose the record with the highest combined score
        confirmed = (
            confirmed.sort_values(["question_id_x", "combined_score"], ascending=False)
            .groupby(["question_id_x"])
            .first()
            .reset_index()
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
        unlinked = df[df["_merge"] == "left_only"].drop(columns="_merge")
        assert not unlinked["uqid"].any(), "Some unlinked records have a uqid"

        assert not self._linked.duplicated(["question_id"]).any()
        linked_dfs = [self._linked, linked]
        if not all([ldf.empty for ldf in linked_dfs]):
            self._linked = pd.concat(
                [df for df in [self._linked, linked] if not df.empty]
            )
            assert not self._linked.duplicated(["question_id"]).any()
        self._unlinked = unlinked

        del self._cross

        self._logger.info("Made fuzzy links.")

        return self

    def prepare_for_insertion(self) -> Self:
        """Prepare data for insertion

        Confirm that the data have the appropriate shape and update
        uqids.

        Returns:
            Self: PIRLinker object
        """

        try:
            self._question_columns
        except AttributeError:
            self._question_columns = self._sql.get_columns("question")

        df = self._data
        df = df.merge(
            self._linked[["question_id", "linked_id", "uqid"]],
            how="left",
            on="question_id",
        )
        assert (
            self._linked.shape[0] == df["linked_id"].notna().sum()
        ), self._logger.error(
            "Count of linked_ids and number of linked records differs."
        )
        assert (
            self._unlinked.shape[0] == df["linked_id"].isna().sum()
        ), "Count of missing linked_ids and number of unlinked records differs."

        del self._linked
        del self._unlinked

        df["uqid"] = df["uqid_x"].combine_first(df["uqid_y"])
        uqid_dict = {}
        df["uqid"] = df.apply(lambda row: self.gen_uqid(row, uqid_dict), axis=1)
        df.drop(columns=["uqid_x", "uqid_y"], inplace=True)
        self._data = df
        self.consolidate_uqids()

        self._logger.info("Records prepared for insertion.")

        return self

    def gen_uqid(self, row: pd.Series, uqid_dict: dict) -> str | float:
        """Generate a uqid

        Args:
            row (pd.Series): A pandas series containing question data
            uqid_dict (dict): A dictionary holding question_id: uqid pairs

        Returns:
            str | float: Unique question ID (uqid)
        """

        if isinstance(row["uqid"], str) and row["uqid"]:
            return row["uqid"]

        if not isinstance(row["linked_id"], str):
            assert np.isnan(
                row["linked_id"]
            ), f"Unexpected value of linked_id: {row["linked_id"]}"
            return row["linked_id"]

        if row["linked_id"] in uqid_dict:
            return uqid_dict[row["linked_id"]]
        else:
            qids_concat = row["question_id"] + row["linked_id"]
            uqid = hashlib.md5(qids_concat.encode()).hexdigest()
            uqid_dict[row["question_id"]] = uqid
            uqid_dict[row["linked_id"]] = uqid
            return uqid

    def update_unlinked(self) -> Self:
        """Update the uqids in the database

        Returns:
            Self: PIRLinker object
        """

        assert (
            self._data["question_id"].unique().shape[0]
            == self._data[~self._data[["question_id", "uqid"]].duplicated()].shape[0]
        ), "uqid varies within question_id"

        records = (
            self._data[["question_id", "uqid"]]
            .rename(columns={"question_id": "qid"})
            .to_dict(orient="records")
        )
        table = self._sql.tables["question"]
        self._sql.update_records(
            table,
            {"uqid": bindparam("uqid")},
            table.c["question_id"] == bindparam("qid"),
            records,
        )

        self._logger.info("uqid updated in question table.")

        return self


if __name__ == "__main__":
    sql_alchemy = SQLAlchemyUtils(**DB_CONFIG, database="pir_test")
    records = sql_alchemy.get_records("SELECT * FROM unlinked").to_dict(
        orient="records"
    )
    linker = PIRLinker(records, sql_alchemy).link().update_unlinked()
