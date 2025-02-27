import hashlib

import numpy as np
import pandas as pd
from fuzzywuzzy import fuzz

from pir_pipeline.utils.MySQLUtils import MySQLUtils


class PIRLinker:
    def __init__(self, df: pd.DataFrame, db_config: dict, databases: list[str]):
        self._df = df
        self._db_config = db_config
        self._sql = MySQLUtils(**db_config).make_db_connections(databases)
        self._question_schemas = self._sql.get_schemas(
            "pir_question_links", ["linked", "unlinked"]
        )._schemas.copy()
        self.get_question_data()

    def get_question_data(self):
        year = self._df["year"].unique()
        assert len(year) == 1
        year = year[0]
        question_columns = self._sql.get_columns(
            "pir_question_links",
            "linked",
            "AND (column_name LIKE '%question%' OR column_name = 'section')",
        )
        question_columns = ",".join(question_columns)
        self._question = self._sql.get_records(
            "pir_data",
            f"SELECT DISTINCT {question_columns} FROM question WHERE year != {year}",
        )

        return self

    def link(self):
        # Look in question table (exclude the current year of data)
        # If question has a match, look for uqid in linked.
        #   If no uqid in linked, generate
        #   Otherwise apply

        # Look for a direct match on question_id
        df = self._df.merge(
            self._question["question_id"].drop_duplicates(),
            how="left",
            on="question_id",
            indicator=True,
        )

        self._linked = df[df["_merge"] == "both"].drop(columns="_merge")
        self._linked["linked_id"] = self._linked["question_id"]
        self._unlinked = df[df["_merge"] == "left_only"].drop(columns="_merge")

        assert not self._linked.duplicated(["question_id"]).any()

        # Look for a fuzzy match on question_name, question_number, or question_text
        self._cross = self._unlinked.merge(self._question, how="cross")
        self.fuzzy_link()
        self.prepare_for_insertion()

        return self

    def fuzzy_link(self):
        def confirm_link(row: pd.Series):
            scores = [item == 100 for item in row.filter(like="score")]
            section = row["section_x"] == row["section_y"]
            return sum(scores) >= 2 and section

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
        self._cross["confirmed"] = self._cross.filter(regex="score|section").apply(
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
        confirmed = confirmed[["question_id", "linked_id"]]

        # Update linked and unlinked
        df = self._unlinked.merge(
            confirmed, how="left", on="question_id", indicator=True
        )
        linked = df[df["_merge"] == "both"].drop(columns="_merge")
        unlinked = df[df["_merge"] == "left_only"].drop(columns="_merge")

        assert not self._linked.duplicated(["question_id"]).any()
        self._linked = pd.concat([self._linked, linked])
        assert not self._linked.duplicated(["question_id"]).any()
        self._unlinked = unlinked

        del self._cross

        return self

    def prepare_for_insertion(self):
        self._df = self._df.merge(
            self._linked[["question_id", "linked_id"]], how="left", on="question_id"
        )
        assert self._linked.shape[0] == self._df["linked_id"].notna().sum()
        assert self._unlinked.shape[0] == self._df["linked_id"].isna().sum()

        self._df["uqid"] = self._df["linked_id"].map(self.gen_uqid)
        self._df.drop(["linked_id"], inplace=True, axis=1)

        return self

    def gen_uqid(self, string: str):
        if not isinstance(string, str):
            assert np.isnan(string), "Unexpected linked_id value"
            return string

        return hashlib.md5(string.encode()).hexdigest()


if __name__ == "__main__":
    import os

    from pir_pipeline.config import db_config
    from pir_pipeline.ingestion.PIRIngestor import PIRIngestor
    from pir_pipeline.utils.paths import INPUT_DIR

    pir_data = PIRIngestor(
        os.path.join(INPUT_DIR, "pir_export_2023.xlsx"),
        db_config,
        databases=["pir_data"],
    ).ingest()
    PIRLinker(
        pir_data._data["question"], db_config, ["pir_question_links", "pir_data"]
    ).link()
