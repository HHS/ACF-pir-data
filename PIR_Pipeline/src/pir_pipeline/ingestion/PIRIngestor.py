import hashlib
import os
import re
from datetime import datetime
from typing import Self

import numpy as np
import pandas as pd
from fuzzywuzzy import fuzz

from pir_pipeline.models import pir_models
from pir_pipeline.utils.MySQLUtils import MySQLUtils


class PIRIngestor:
    def __init__(self, workbook: str | os.PathLike, db_config: dict, database: str):
        """Initialize a PIRIngestor object

        Args:
            workbook (str|os.PathLike): File path to an Excel Workbook
        """
        self._data: dict[pd.DataFrame] = {}
        self._sql = MySQLUtils(**db_config)
        self._database = database

        self._workbook = workbook

    def make_snake_name(self, name: str) -> str:
        """Convert a name to snake case

        Args:
            name (str): A name to convert

        Returns:
            str: Snake-cased name
        """
        snake_name = re.sub(r"\W", "_", name.lower())
        snake_name = re.sub(r"_+", "_", snake_name)
        return snake_name

    def duplicated_question_error(
        self, df: pd.DataFrame, columns: list[str]
    ) -> pd.DataFrame:
        """Resolve duplicated questions

        This function is run when a duplicate question appears in the data. In that case,
        the data are sorted, grouped, and the first record in each group is taken.

        Args:
            df (pd.DataFrame): A data frame containing duplicates
            columns (list[str]): A list of columns to group on

        Returns:
            pd.DataFrame: A deduplicated data frame
        """
        df.sort_values(columns + ["question_order"], inplace=True)
        df = df.groupby(columns).sample(1).reset_index().drop(columns="index")
        return df

    def missing_question_error(
        self, response: pd.DataFrame, question: pd.DataFrame, missing_questions: set
    ) -> pd.DataFrame:
        """Add missing questions to the question data

        Args:
            response (pd.DataFrame): Response data frame
            question (pd.DataFrame): Question data frame
            missing_questions (set): A set of missing questions

        Returns:
            pd.DataFrame: Question data frame, updated to contain missing questions
        """
        response = (
            response[["question_number", "question_name", "section"]][
                response["question_number"].isin(missing_questions)
            ]
            .groupby(["question_number", "question_name"])
            .sample(1)
        )
        question = pd.concat([question, response])

        return question

    def get_section(self, question_number: str) -> str:
        """Extract the section from a question number

        Args:
            question_number (str): A string question number

        Returns:
            str: The section in which the question appears
        """
        if not isinstance(question_number, str):
            return ""

        section = re.search("^([A-Z])", question_number)
        if section:
            return section.group(1)

        return ""

    def hash_columns(self, row: pd.Series) -> str:
        """Return the md5 hash of a series of columns

        Args:
            row (pd.Series): A series of columns to hash

        Returns:
            str: Hashed columns
        """
        string = "".join([str(item) for item in row])
        byte_string = string.encode()

        return hashlib.md5(byte_string).hexdigest()

    def extract_sheets(self) -> Self:
        """Load the workbook, and extract sheets and year.

        Returns:
            Self: PIRIngestor object
        """
        self._year = re.search(r"(\d{4})\.(csv|xlsx?)$", self._workbook).group(1)
        self._workbook = pd.ExcelFile(self._workbook)
        self._sheets = self._workbook.sheet_names
        return self

    def load_data(self) -> Self:
        """Load data from each sheet of the workbook

        Returns:
            Self: PIRIngestor object
        """
        for sheet in self._sheets:
            name = self.make_snake_name(sheet)
            section_condition = sheet.find("Section") > -1
            reference_condition = sheet == "Reference"
            program_condition = sheet.find("Program") > -1
            if not (section_condition or reference_condition or program_condition):
                continue

            df = pd.read_excel(self._workbook, sheet, dtype="object")

            if section_condition:
                df = pd.read_excel(self._workbook, sheet, header=None)
                duplicated_names = {}
                column_names = []
                header = df.iloc[[1]].melt(value_name="question_number")
                for column_name in header["question_number"].tolist():
                    if column_name not in duplicated_names:
                        duplicated_names[column_name] = 0
                        column_names.append(column_name)
                        continue

                    # Add an _\d to deduplicate question number.
                    # Needed for the merge of question name.
                    duplicated_names[column_name] += 1
                    column_names.append(
                        str(column_name) + f"_{duplicated_names[column_name]}"
                    )

                df.columns = column_names
                question_names = df.iloc[[0]].melt(
                    var_name="question_number", value_name="question_name"
                )
                df = df.melt(
                    id_vars=[
                        "Region",
                        "State",
                        "Grant Number",
                        "Program Number",
                        "Type",
                        "Grantee",
                        "Program",
                        "City",
                        "ZIP Code",
                        "ZIP 4",
                    ],
                    var_name="question_number",
                    value_name="answer",
                ).merge(
                    question_names,
                    how="left",
                    on="question_number",
                    validate="many_to_one",
                )
                df["section"] = df["question_number"].map(self.get_section)
                df = df[df["Region"] != "Region"]
                df = df[df["Grant Number"].notna()]

                assert df[
                    "question_name"
                ].all(), "Some questions are missing a question name"

            elif reference_condition:
                df.columns = df.columns.map(self.make_snake_name)
                unique_columns = ["question_number", "question_name"]
                try:
                    assert not df[unique_columns].duplicated().any()
                except AssertionError:
                    df = self.duplicated_question_error(df, unique_columns)
                    assert (
                        not df[unique_columns].duplicated().any()
                    ), f"Some observations are still duplicated:\n {df[df[unique_columns].duplicated()]}"

                df["section"] = df["question_number"].map(self.get_section)
                name = "question"

            elif program_condition:
                name = "program"

            df.columns = df.columns.map(self.make_snake_name)
            self._data[name] = df

        return self

    def append_sections(self) -> Self:
        df_list = []
        to_delete = []
        for name, df in self._data.items():
            if name.find("section") > -1:
                df_list.append(df)
                to_delete.append(name)

        self._data["response"] = pd.concat(df_list)

        for name in to_delete:
            del self._data[name]

        return self

    def merge_response_question(self) -> Self:
        # Response data
        def gen_question_number(string: str):
            if not isinstance(string, str):
                return string

            string = re.sub(r"_\d+$", "", string)

            if string == "nan":
                return np.nan

            return string

        response = self._data["response"]
        response["question_number"] = response["question_number"].map(
            gen_question_number
        )

        # Question data
        question = self._data["question"]

        # Confirm all questions are in question
        missing_questions = set(response["question_number"]) - set(
            question["question_number"]
        )
        try:
            assert missing_questions == set()
        except AssertionError:
            question = self.missing_question_error(
                response, question, missing_questions
            )
            missing_questions = set(response["question_number"]) - set(
                question["question_number"]
            )
            assert (
                missing_questions == set()
            ), f"Some questions are missing: {missing_questions}"

        # Merge
        response = response.merge(
            question.drop(columns=["type"]),
            how="left",
            on=["question_number", "question_name"],
            validate="many_to_one",
            indicator=True,
        )
        assert (
            not response[
                [
                    "grant_number",
                    "program_number",
                    "type",
                    "question_number",
                    "question_name",
                ]
            ]
            .duplicated()
            .any()
        ), "Some records are duplicated"

        for column in response.columns.tolist():
            if column.endswith("_x"):
                column_y = column.replace("_x", "_y")
                base_column = column.replace("_x", "")
                response[base_column] = response[column].combine_first(
                    response[column_y]
                )
                response.drop(columns=[column, column_y], inplace=True)

        self._data["response"] = response

        return self

    def clean_pir_data(self) -> Self:
        def get_region(region: str):
            region = re.sub(r"\D+", "", region)
            if region:
                return int(region)

            return None

        self._sql.make_connection(self._database).get_schemas(
            ["response", "program", "question"]
        )
        uid_columns = ["grant_number", "program_number", "program_type"]
        qid_columns = ["question_number", "question_name"]

        # Clean response data
        response = self._data["response"]
        response.rename(columns={"type": "program_type"}, inplace=True)
        duplicates = response[response[uid_columns + qid_columns].duplicated()]
        assert duplicates.empty, f"Some duplicated records:\n{duplicates}"
        response["uid"] = response[uid_columns].apply(self.hash_columns, axis=1)
        response["question_id"] = response[qid_columns].apply(self.hash_columns, axis=1)
        response["answer"] = response["answer"].map(self.stringify)

        # Program
        program = self._data["program"]
        program.rename(
            columns={
                "program_zip_code": "program_zip1",
                "program_zip_4": "program_zip2",
                "program_main_phone_number": "program_phone",
                "program_main_email": "program_email",
            },
            inplace=True,
        )
        duplicates = program[program[uid_columns].duplicated()]
        assert duplicates.empty, f"Some duplicated records:\n{duplicates}"
        program["uid"] = program[uid_columns].apply(self.hash_columns, axis=1)
        program["region"] = program["region"].map(get_region)

        # Question
        question = self._data["question"]
        question.rename(columns={"type": "question_type"}, inplace=True)
        duplicates = question[question[qid_columns].duplicated()]
        assert duplicates.empty, f"Some duplicated records:\n{duplicates}"
        question["question_id"] = question[qid_columns].apply(self.hash_columns, axis=1)

        # Add year, subset to relevant variables only
        for frame in ["response", "program", "question"]:
            final_columns = self._sql._schemas[frame]["Field"]
            df = eval(frame)
            df["year"] = self._year
            missing_variables = set(final_columns) - set(df.columns)
            for var in missing_variables:
                df[var] = None
            df = df[final_columns]
            self._data[frame] = df

        return self

    def stringify(self, value) -> str:
        if isinstance(value, str):
            return value
        elif isinstance(value, datetime):
            return value.strftime("%m/%d/%Y")
        elif np.isnan(value):
            return np.nan
        elif isinstance(value, (int, float)):
            return str(value)

        return value

    def get_question_data(self):
        question_columns = self._sql.get_columns(
            "question",
            "AND (column_name LIKE '%question%' OR column_name IN ('section', 'uqid'))",
        )
        question_columns = ",".join(question_columns)
        self._question = self._sql.get_records(
            f"SELECT DISTINCT {question_columns} FROM question WHERE year != {self._year}",
        )

        return self

    def link(self):
        # Look in question table (exclude the current year of data)
        # If question has a match, look for uqid in linked.
        #   If no uqid in linked, generate
        #   Otherwise apply

        # Look for a direct match on question_id
        self.get_question_data()
        df = self._data["question"].copy()
        df = df.merge(
            self._question[["question_id", "uqid"]].drop_duplicates(),
            how="left",
            on="question_id",
            indicator=True,
        )

        df["linked_id"] = df["question_id"]
        df["uqid"] = df["uqid_x"].combine_first(df["uqid_y"])
        df.drop(["uqid_x", "uqid_y"], axis=1, inplace=True)

        self._linked = df[df["_merge"] == "both"].drop(columns="_merge")
        self._unlinked = df[df["_merge"] == "left_only"].drop(columns="_merge")

        assert not self._linked.duplicated(["question_id"]).any()

        # Look for a fuzzy match on question_name, question_number, or question_text
        self._cross = self._unlinked.merge(self._question, how="cross")
        if not self._cross.empty:
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
        confirmed["uqid"] = confirmed["uqid_x"].combine_first(confirmed["uqid_y"])
        confirmed = confirmed[["question_id", "linked_id", "uqid"]]

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
        df = self._data["question"]
        df = df.merge(
            self._linked[["question_id", "linked_id"]], how="left", on="question_id"
        )
        assert self._linked.shape[0] == df["linked_id"].notna().sum()
        assert self._unlinked.shape[0] == df["linked_id"].isna().sum()

        del self._linked
        del self._unlinked

        df["uqid"] = df.apply(lambda row: self.gen_uqid(row), axis=1)

        self._data["question"] = df
        self.update_unlinked()
        self._data["question"].drop(["linked_id"], inplace=True, axis=1)

        return self

    def gen_uqid(self, row: pd.Series):
        if isinstance(row["uqid"], str) and row["uqid"]:
            return row["uqid"]

        if not isinstance(row["linked_id"], str):
            assert np.isnan(
                row["linked_id"]
            ), f"Unexpected value of linked_id: {row["linked_id"]}"
            return row["linked_id"]

        return hashlib.md5(row["linked_id"].encode()).hexdigest()

    def insert_data(self):
        for table, df in self._data.items():
            df.replace({np.nan: None}, inplace=True)
            model = getattr(pir_models, f"{table.title()}Model")
            initial_records = df.to_dict(orient="records")
            cleaned_records = []
            for record in initial_records:
                cleaned = model.model_validate(record).model_dump()
                cleaned_records.append(cleaned)

            columns = tuple(df.columns.to_list())
            self._sql.insert_records(columns, cleaned_records, table)

        if not self._unlinked.empty:
            self._unlinked.apply(
                lambda row: self._sql.update_records(
                    "question",
                    {"uqid": row["uqid"]},
                    f"question_id = '{row["question_id"]}'",
                ),
                axis=1,
            )

    def update_unlinked(self):
        unlinked = self._sql.get_records("SELECT DISTINCT question_id FROM unlinked")
        unlinked = unlinked.merge(
            self._data["question"][["linked_id", "uqid"]],
            how="inner",
            left_on="question_id",
            right_on="linked_id",
        )

        self._unlinked = unlinked

        return self

    def ingest(self):
        (
            self.extract_sheets()
            .load_data()
            .append_sections()
            .merge_response_question()
            .clean_pir_data()
            .link()
            .insert_data()
        )

        self._sql.close_connection()

        return self

    # def linked_checks(self, df: pd.DataFrame):
    #     """Method for confirming that, upon reingestion, uqid remains consistent.

    #     Args:
    #         df (pd.DataFrame): Data frame that will ultimately become re-ingested question.
    #     """
    #     query = "SELECT * FROM linked WHERE year = %s" % self._year
    #     linked = self._sql.get_records(query)
    #     merged = df.merge(linked, on="question_id", how="right", indicator=True)

    #     assert merged["_merge"].map(lambda x: x == "both").all()
    #     assert merged.apply(lambda row: row["uqid_x"] == row["uqid_y"], axis=1).all()


if __name__ == "__main__":
    from pir_pipeline.config import db_config
    from pir_pipeline.utils.paths import INPUT_DIR

    files = os.listdir(INPUT_DIR)
    for file in files:
        year = re.search(r"\d{4}", file).group(0)
        year = int(year)
        if year < 2008:
            continue
        elif year == 2008 and file.endswith(".xlsx"):
            continue
        elif year > 2009:
            continue

        PIRIngestor(os.path.join(INPUT_DIR, file), db_config, database="pir").ingest()
