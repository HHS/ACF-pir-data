"""Class for ingesting and linking PIR data"""

import hashlib
import logging
import os
import re
from datetime import datetime
from typing import Any, Self

import numpy as np
import pandas as pd
from fuzzywuzzy import fuzz
from sqlalchemy import bindparam

from pir_pipeline.models import pir_models
from pir_pipeline.utils import SQLAlchemyUtils


class PIRIngestor:
    def __init__(self, workbook: str | os.PathLike, sql: SQLAlchemyUtils):
        """Initialize a PIRIngestor object

        Args:
            workbook (str|os.PathLike): File path to an Excel Workbook
        """
        self._data: dict[pd.DataFrame] = {}
        self._sql = sql
        self._workbook = workbook
        self._metrics: dict = {}
        logging.basicConfig(
            format="%(asctime)s|%(levelname)s|%(message)s",
            level=logging.DEBUG,
            datefmt="%Y-%m-%d %I:%M:%S",
        )
        self._logger = logging.getLogger(__name__)
        self._logger.info("Initialized ingestor.")

    def make_snake_name(self, name: str) -> str:
        """Convert a name to snake case

        Args:
            name (str): A name to convert

        Returns:
            str: Snake-cased name
        """
        assert isinstance(name, str), self._logger.error(
            "Input `name` must be a string."
        )
        assert name.strip() != "", self._logger.error(
            "Input `name` cannot be an empty or whitespace-only string."
        )

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
        df = df.groupby(columns).first().reset_index()
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

        REQUIRED_COLS = ["question_number", "question_name", "section"]

        assert isinstance(
            response, pd.DataFrame
        ), "Input `response` must be a dataframe."
        assert isinstance(
            question, pd.DataFrame
        ), "Input `question` must be a dataframe."
        assert isinstance(
            missing_questions, set
        ), "Input `missing_questions` must be a set."

        assert (
            set(REQUIRED_COLS) - set(response.columns.tolist()) == set()
        ), f"Input `response` must have columns {REQUIRED_COLS}."
        assert (
            set(REQUIRED_COLS) - set(question.columns.tolist()) == set()
        ), f"Input `question` must have columns {REQUIRED_COLS}."

        numrows_q = question.shape[0]

        response = (
            response[["question_number", "question_name", "section"]][
                response["question_number"].isin(missing_questions)
            ]
            .groupby(["question_number", "question_name"])
            .sample(1)
        )

        expected_numrows = numrows_q + response.shape[0]

        question = pd.concat([question, response])

        assert (
            question.shape[0] == expected_numrows
        ), f"Output of missing_question_error is an incorrect length. Expected {expected_numrows}."

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

    def hash_columns(self, row: str | pd.Series) -> str:
        """Return the md5 hash of a series of columns

        Args:
            row (pd.Series): A series of columns to hash

        Returns:
            str: Hashed columns
        """

        if isinstance(row, pd.Series):
            assert not row.isna().all(), self._logger.error(
                "All values in the row are None or nan."
            )
            assert not row.empty, self._logger.error("Input row is empty")

            string = "".join([str(item) for item in row])
        else:
            string = row

        byte_string = string.encode()

        return hashlib.md5(byte_string).hexdigest()

    def extract_sheets(self) -> Self:
        """Load the workbook, and extract sheets and year.

        Returns:
            Self: PIRIngestor object
        """
        year = re.search(r"(\d{4})\.(csv|xlsx?)$", self._workbook)
        assert year, self._logger.error(
            "Workbook does not contain the year in the file name."
        )
        self._year = int(year.group(1))
        self._workbook = pd.ExcelFile(self._workbook)
        self._sheets = self._workbook.sheet_names

        self._logger.info("Extracted worksheets.")

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
                try:
                    self._metrics["response"]
                except KeyError:
                    self._metrics["response"] = {}
                    self._metrics["response"]["record_count"] = 0

                # Must subtract 1 from the count because first two rows are headers
                self._metrics["response"]["record_count"] += df.shape[0] - 1

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
                name = "question"
                self._metrics[name] = {}
                self._metrics[name]["record_count"] = df.shape[0]

                df.columns = df.columns.map(self.make_snake_name)
                unique_columns = ["question_number", "question_name"]
                dupes = df[unique_columns].duplicated().sum()
                try:
                    assert not dupes, self._logger.error(
                        f"{dupes} duplicated questions"
                    )
                except AssertionError:
                    df = self.duplicated_question_error(df, unique_columns)
                    self._metrics["question"]["dupes"] = dupes
                    assert (
                        not df[unique_columns].duplicated().any()
                    ), f"Some observations are still duplicated:\n {df[df[unique_columns].duplicated()]}"

                df["section"] = df["question_number"].map(self.get_section)

            elif program_condition:
                name = "program"
                self._metrics[name] = {}
                self._metrics[name]["record_count"] = df.shape[0]

            df.columns = df.columns.map(self.make_snake_name)
            self._data[name] = df

        self._logger.info("Loaded data.")

        return self

    def append_sections(self) -> Self:
        """Append the loaded section data to generate the response table

        Returns:
            Self: PIRIngestor Object
        """
        df_list = []
        to_delete = []
        for name, df in self._data.items():
            if name.find("section") > -1:
                df_list.append(df)
                to_delete.append(name)

        self._data["response"] = pd.concat(df_list)

        for name in to_delete:
            del self._data[name]

        self._logger.info("Appended 'Section' worksheets.")

        return self

    def merge_response_question(self) -> Self:
        """Merge response and question data frames

        Merges the response and question data frames to: 1) get question text onto the
        response data frame for question_id generation, 2) ensure that all questions
        that appear in the response data frame appear in the question data frame.

        Returns:
            Self: PIRIngestor object
        """

        def gen_question_number(string: str):
            if not isinstance(string, str):
                return string

            string = re.sub(r"_\d+$", "", string)

            if string == "nan":
                return np.nan

            return string

        # Response data
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

            self._data["question"] = question

        # Merge
        original_response = response.copy()
        merge_columns = ["question_number", "question_name"]
        response = response.merge(
            question.drop(columns=["type"]),  # Why not just get the necessary columns?
            how="left",
            on=merge_columns,
            validate="many_to_one",
            indicator=True,
        )
        try:
            num_records = response.shape[0]
            assert (response["_merge"] == "both").all()
        except AssertionError:
            both = response[response["_merge"] == "both"].drop(columns="_merge")
            left = response[response["_merge"] == "left_only"].drop(columns="_merge")
            left = left[merge_columns][~left[merge_columns].duplicated()]

            left = (
                original_response.merge(
                    left,
                    how="inner",
                    on=merge_columns,
                    validate="many_to_one",
                )
                .drop(columns="question_name")
                .merge(
                    question.drop(columns=["type"]),
                    how="left",
                    on="question_number",
                    validate="many_to_one",
                    indicator=True,
                )
            )

            assert (left["_merge"] == "both").all()
            assert set(both.columns.tolist()) - set(left.columns.tolist()) == set()
            appended = pd.concat([both, left])
            assert appended.shape[0] == num_records
            response = appended

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

        # Combine any columns that appear twice due to merging
        for column in response.columns.tolist():
            if column.endswith("_x"):
                column_y = column.replace("_x", "_y")
                base_column = column.replace("_x", "")
                response[base_column] = response[column].combine_first(
                    response[column_y]
                )
                response.drop(columns=[column, column_y], inplace=True)

        self._data["response"] = response

        self._logger.info("Merged response and question data.")

        return self

    def clean_pir_data(self) -> Self:
        """Align the PIR data with PIR database schemas

        Returns:
            Self: PIRIngestor object
        """

        def get_region(region: str):
            region = re.sub(r"\D+", "", region)
            if region:
                return int(region)

            return None

        self._sql.get_schemas(["response", "program", "question"])
        uid_columns = ["grant_number", "program_number", "program_type"]
        qid_columns = ["question_number", "question_name"]

        # Clean response data
        response = self._data["response"]
        response.rename(columns={"type": "program_type"}, inplace=True)
        duplicates = response[response[uid_columns + qid_columns].duplicated()]
        assert duplicates.empty, self._logger.error(
            f"Some duplicated records:\n{duplicates}"
        )

        # Logic adapted from GPT
        for columns in [uid_columns, qid_columns]:
            assert (
                response[columns].isna().sum(axis=1) < len(columns)
            ).all(), self._logger.error(
                f"One row has missing values for all of: {columns}"
            )
        response["uid"] = response[uid_columns].astype(str).agg("".join, axis=1)
        response["uid"] = response["uid"].apply(self.hash_columns)
        response["question_id"] = response[qid_columns].astype(str).agg("".join, axis=1)
        response["question_id"] = response["question_id"].apply(self.hash_columns)

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
        try:
            assert duplicates.empty, self._logger.error(
                f"Some duplicated records:\n{duplicates}"
            )
        except AssertionError:
            # For now, simply remove duplicates if any occur
            program = program[~program[uid_columns].duplicated()]

        program["uid"] = program[uid_columns].apply(self.hash_columns, axis=1)
        program["region"] = program["region"].map(get_region)

        # Question
        question = self._data["question"]
        question.rename(columns={"type": "question_type"}, inplace=True)
        duplicates = question[question[qid_columns].duplicated()]
        assert duplicates.empty, self._logger.error(
            f"Some duplicated records:\n{duplicates}"
        )
        question["question_id"] = question[qid_columns].apply(self.hash_columns, axis=1)

        # Add year, subset to relevant variables only
        data = {"response": response, "program": program, "question": question}
        for frame in data:
            final_columns = self._sql._schemas[frame]["Field"]
            df = data[frame]
            df["year"] = self._year
            missing_variables = set(final_columns) - set(df.columns)
            for var in missing_variables:
                df[var] = None
            df = df[final_columns]
            self._data[frame] = df

        self._logger.info("Cleaned PIR data to prepare for insertion.")

        return self

    def stringify(self, value: Any) -> str:
        """Convert values to string

        In the case of dates, this function applies the Month/Day/Year format.

        Args:
            value (Any): Value to convert to string

        Returns:
            str: Original value converted to string
        """
        if isinstance(value, str):
            return value
        elif isinstance(value, datetime):
            return value.strftime("%m/%d/%Y")
        elif isinstance(value, (int, float)):
            if np.isnan(value):
                return "nan"
            if isinstance(value, bool):
                return value
            return str(value)

        return value

    def get_question_data(self) -> Self:
        """Select distinct questions from the question table

        Returns:
            Self: PIRIngestor object
        """
        question_columns = self._sql.get_columns(
            "question",
            "AND (column_name LIKE '%question%' OR column_name IN ('section', 'uqid'))",
        )
        question_columns = ",".join(question_columns)
        self._question = self._sql.get_records(
            f"SELECT DISTINCT {question_columns} FROM question WHERE year != {self._year}",
        )
        try:
            assert not self._question["question_id"].duplicated().any()
        except AssertionError:
            self._question = (
                self._question.groupby(["question_id"]).first().reset_index()
            )
            assert (
                not self._question["question_id"].duplicated().any()
            ), "Duplicated question_ids"

        return self

    def link(self) -> Self:
        """Create links between existing questions and newly ingested questions

        Returns:
            Self: PIRIngestor object
        """

        # Look for a direct match on question_id
        self.get_question_data()
        df = self._data["question"].copy()
        df = df.merge(
            self._question[["question_id", "uqid"]].drop_duplicates(),
            how="left",
            on="question_id",
            indicator=True,
        )

        df["uqid"] = df["uqid_x"].combine_first(df["uqid_y"])
        df.drop(columns=["uqid_x", "uqid_y"], inplace=True)

        self._linked = df[df["_merge"] == "both"].drop(columns="_merge")
        self._linked["linked_id"] = self._linked["question_id"]
        self._unlinked = df[df["_merge"] == "left_only"].drop(columns="_merge")

        assert not self._linked.duplicated(["question_id"]).any()

        # Look for a fuzzy match on question_name, question_number, or question_text
        self._cross = self._unlinked.merge(
            self._question,
            how="left",
            on=["question_type", "section"],
            validate="many_to_many",
        )
        if not self._cross.empty:
            self.fuzzy_link()

        self.prepare_for_insertion()

        self._logger.info("Linked new questions to extant questions.")

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
        df = self._data["question"]
        assert df["uqid"].isna().all()
        df.drop(columns="uqid", inplace=True)
        df = df.merge(
            self._linked[["question_id", "linked_id", "uqid"]],
            how="left",
            on="question_id",
        )
        assert self._linked.shape[0] == df["linked_id"].notna().sum()
        assert self._unlinked.shape[0] == df["linked_id"].isna().sum()

        del self._linked
        del self._unlinked

        df["uqid"] = df.apply(lambda row: self.gen_uqid(row), axis=1)

        self._data["question"] = df
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
            ), f"Unexpected value of linked_id: {row['linked_id']}"
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

    def validate_data(self) -> Self:
        def check_dupes(metric_dict: dict):
            return metric_dict["record_count"] - metric_dict["dupes"]

        assert (
            self._data["program"].shape[0] == self._metrics["program"]["record_count"]
        ), self._logger.error("Program count has changed.")
        try:
            assert (
                self._data["question"].shape[0]
                >= self._metrics["question"]["record_count"]
            ), self._logger.error("Question count is too low")
        except AssertionError:
            assert self._data["question"].shape[0] >= check_dupes(
                self._metrics["question"]
            ), self._logger.error("Question count is too low")
            self._logger.info("Question count is accurate without duplicates.")
        assert (
            self._data["response"]["uid"].nunique()
            == self._metrics["program"]["record_count"]
        ), self._logger.error("Incorrect program count in response.")
        try:
            assert (
                self._data["response"]["question_id"].nunique()
                >= self._metrics["question"]["record_count"]
            ), self._logger.error("Too few questions in response.")
        except AssertionError:
            assert self._data["response"]["question_id"].nunique() >= check_dupes(
                self._metrics["question"]
            ), self._logger.error("Too few questions in response.")
            self._logger.info("Response question count is accurate without duplicates.")

        self._logger.info("Validated data.")

        return self

    def insert_data(self) -> Self:
        """Insert data into the target database

        Returns:
            Self: PIRIngestor object
        """

        # Loop through program, question, and response tables and insert records
        for table, df in self._data.items():
            df.replace({np.nan: None}, inplace=True)
            model = getattr(pir_models, f"{table.title()}Model")
            initial_records = df.to_dict(orient="records")
            cleaned_records = []

            # Validate the records with pydantic model
            for record in initial_records:
                cleaned = model.model_validate(record).model_dump()
                cleaned_records.append(cleaned)

            self._sql.insert_records(cleaned_records, table)

        self._logger.info(f"Data inserted for {self._year}")

        # Update unlinked records if necessary
        if not self._unlinked.empty:
            self._unlinked.rename(columns={"question_id": "qid"}, inplace=True)
            records = self._unlinked.to_dict(orient="records")
            table = self._sql.tables["question"]
            self._sql.update_records(
                table,
                {"uqid": bindparam("uqid")},
                table.c["question_id"] == bindparam("qid"),
                records,
            )

        self._logger.info(f"Unlinked records updated for {self._year}")

        return self

    def ingest(self) -> Self:
        """Ingestion entry point

        Returns:
            Self: PIRIngestor object
        """
        (
            self.extract_sheets()
            .load_data()
            .append_sections()
            .merge_response_question()
            .clean_pir_data()
            .link()
            .validate_data()
            .insert_data()
        )

        return self


if __name__ == "__main__":
    import time

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
        # elif year != 2010:
        #     continue

        try:
            init = time.time()
            PIRIngestor(
                os.path.join(INPUT_DIR, file),
                SQLAlchemyUtils(**db_config, database="pir"),
            ).ingest()
            fin = time.time()
            print(f"Time to process {year}: {(fin-init)/60} minutes")
        except Exception:
            print(year)
            fin = time.time()
            print(f"Time to process {year}: {(fin-init)/60} minutes")
            raise
