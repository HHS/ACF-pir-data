"""Class for ingesting and linking PIR data"""

import hashlib
import os
import re
from datetime import datetime
from typing import Any, Self

import numpy as np
import pandas as pd

from pir_pipeline.models import pir_models
from pir_pipeline.utils.SQLAlchemyUtils import SQLAlchemyUtils
from pir_pipeline.utils.utils import get_logger


class PIRIngestor:
    def __init__(self, workbook: str | os.PathLike, sql: SQLAlchemyUtils):
        """Initialize a PIRIngestor object

        Args:
            workbook (str|os.PathLike): File path to an Excel Workbook
        """
        self._data: dict[pd.DataFrame] = {}
        sql.create_db()
        self._sql = sql
        self._workbook = workbook
        self._metrics: dict = {}
        self._logger = get_logger(__name__)
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
            .first()
            .reset_index()
        )

        expected_row_count = numrows_q + response.shape[0]
        # in some cases the question_number is missing but the question_name is present
        # fill in the missing question_number values
        question_table_only_missing_question_numbers = (
            response["question_name"].tolist()
            == question[question["question_name"].isin(response["question_name"])][
                "question_name"
            ].tolist()
        )
        if question_table_only_missing_question_numbers:
            expected_row_count = question.shape[0]
            question_corrected = (
                question[question["question_number"].isna()]
                .drop(["question_number", "section"], axis=1)
                .merge(
                    response, on=["question_name"], how="left", validate="one_to_one"
                )
            )
            question_corrected = question_corrected[question.columns]

            question = pd.concat(
                [question[question["question_number"].notna()], question_corrected]
            ).sort_values("question_order")

        # in most cases the response table has a full record that the question table is missing
        else:
            expected_row_count = numrows_q + response.shape[0]
            question = pd.concat([question, response])

        assert (
            question.shape[0] == expected_row_count
        ), f"Output of missing_question_error is an incorrect length. Expected {expected_row_count}."

        return question

    def get_section(self, question_number: str) -> str:
        """Extract the section from a question number

        Args:
            question_number (str): A string question number

        Returns:
            str: The section in which the question appears
        """
        if not isinstance(question_number, str):
            return None

        section = re.search("^([A-Z])", question_number)
        if section:
            return section.group(1)

        return None

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
        assert len(self._sheets) > 0, f"Workbook {self._workbook} was empty."

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
                # Get question names by reshaping long
                question_names = df.iloc[[0]].melt(
                    var_name="question_number", value_name="question_name"
                )
                # Reshape entire dataset long and merge question names
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

                assert (
                    df["question_name"].notna().all()
                ), "Some questions are missing a question name"

            elif reference_condition:
                name = "question"
                self._metrics[name] = {}
                self._metrics[name]["record_count"] = df.shape[0]

                df.columns = df.columns.map(self.make_snake_name)

                # Hash columns to track original question ids for validation
                unique_columns = ["question_number", "question_name"]
                question_ids = set(
                    df[unique_columns].apply(self.hash_columns, axis=1).tolist()
                )
                self._metrics[name]["question_ids"] = question_ids
                self._metrics[name]["nan_question_number"] = df[
                    df["question_number"].isna()
                ]

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
                    ), self._logger.error(
                        f"Some observations are still duplicated:\n {df[df[unique_columns].duplicated()]}"
                    )

                df["section"] = df["question_number"].map(self.get_section)

            elif program_condition:
                name = "program"
                self._metrics[name] = {}
                self._metrics[name]["record_count"] = df.shape[0]

            df.columns = df.columns.map(self.make_snake_name)
            self._data[name] = df

        self.close_excel_files()
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
                string = np.nan

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

        # If section is ever missing, attempt to merge it on using category and subsection
        if question["section"].isna().any():
            grouping_vars = ["category", "subsection"]
            assert (
                question.groupby(grouping_vars)["section"]
                .unique()
                .map(lambda x: len(x) == 1 or (len(x) == 2 and None in x))
                .all()
            ), self._logger.error(
                "Category and subsection do not uniquely identify section"
            )
            assert not any(question[grouping_vars].isna().any()), self._logger.error(
                f"One of {grouping_vars} is sometimes None: {question[grouping_vars].isna().any()}"
            )
            sections = question[grouping_vars + ["section"]].dropna().drop_duplicates()
            question = question.merge(
                sections,
                how="left",
                on=["category", "subsection"],
                validate="many_to_one",
                indicator=True,
            )
            # Sometimes all questions in a category/subsection combination are missing section
            # Also means final check is invalid
            # assert (question["_merge"] == "both").all(), self._logger.error(
            #     "Some category/section combinations do not align"
            # )
            question["section"] = question["section_x"].combine_first(
                question["section_y"]
            )
            question.drop(columns=["section_x", "section_y", "_merge"], inplace=True)
            # assert not question["section"].isna().any(), self._logger.error(
            #     "Some section information still missing"
            # )

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

        # Check to see if all questions in response have a matching record in question
        # Can occur because sometimes question name is different in response and question
        try:
            num_records = response.shape[0]
            assert (response["_merge"] == "both").all()
        # If not, correct this
        except AssertionError:
            # Extract records matched in both and response only
            both = response[response["_merge"] == "both"].drop(columns="_merge")
            left = response[response["_merge"] == "left_only"].drop(columns="_merge")

            # Drop duplicated questions
            left = left[merge_columns][~left[merge_columns].duplicated()]

            # Get the original records from response and merge to question on
            # only question_number
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

            assert (
                left["_merge"] == "both"
            ).all(), "Some records in response still not found in question"
            assert (
                set(both.columns.tolist()) - set(left.columns.tolist()) == set()
            ), "Different columns in both and left"
            appended = pd.concat([both, left])
            assert appended.shape[0] == num_records, self._logger.error(
                "Incorrect number of records after dataframe concatenation"
            )
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
        ), self._logger.error("Some records are duplicated")

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

        self._columns = {
            table: self._sql.get_columns(table)
            for table in ["response", "question", "program"]
        }
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
            final_columns = self._columns[frame]
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

    def validate_data(self) -> Self:
        """Validate the cleaned PIR data

        Returns:
            Self: PIRIngestor object
        """

        def check_dupes(metric_dict: dict):
            return metric_dict["record_count"] - metric_dict["dupes"]

        response = self._data["response"]
        question = self._data["question"]
        program = self._data["program"]
        metrics = self._metrics

        assert (
            program.shape[0] == metrics["program"]["record_count"]
        ), self._logger.error("Program count has changed.")
        try:
            assert (
                question.shape[0] >= metrics["question"]["record_count"]
            ), self._logger.error("Question count is too low")
        except AssertionError:
            assert question.shape[0] >= check_dupes(
                metrics["question"]
            ), self._logger.error("Question count is too low")
            self._logger.info("Question count is accurate without duplicates.")

        try:
            set_diff = set(question["question_id"].unique()).symmetric_difference(
                metrics["question"]["question_ids"]
            )
            assert set_diff, self._logger.error(
                f"question_ids differ in raw and processed data: {set_diff}"
            )
        except AssertionError:
            question_diff = question[
                [qid in set_diff for qid in question["question_id"]]
            ]
            assert set(question_diff["question_name"]) == set(
                metrics["question"]["nan_question_number"]["question_name"]
            ), self._logger.error(
                "question_ids differ after accounting for nan question_numbers"
            )
            self._logger.info(
                "question_ids align after accounting for nan question_numbers"
            )

        # Confirm response record count and ids
        assert (
            response["uid"].nunique() == metrics["program"]["record_count"]
        ), self._logger.error("Incorrect program count in response.")
        try:
            assert (
                response["question_id"].nunique() >= metrics["question"]["record_count"]
            ), self._logger.error("Too few questions in response.")
        except AssertionError:
            assert response["question_id"].nunique() >= check_dupes(
                metrics["question"]
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
            .validate_data()
            .insert_data()
        )

        return self

    def close_excel_files(self):
        """Close all Excel files"""
        workbooks = self._workbook
        if isinstance(workbooks, dict):
            for book in workbooks.values():
                book.close()
        else:
            workbooks.close()

        self._workbook.close()


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
        elif year != 2008:
            continue

        try:
            init = time.time()
            PIRIngestor(
                os.path.join(INPUT_DIR, file),
                SQLAlchemyUtils(
                    **db_config, database="pir", drivername="postgresql+psycopg"
                ),
            ).ingest()
            fin = time.time()
            print(f"Time to process {year}: {(fin-init)/60} minutes")
        except Exception:
            print(year)
            fin = time.time()
            print(f"Time to process {year}: {(fin-init)/60} minutes")
            raise
