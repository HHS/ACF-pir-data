import hashlib
import os
import re
from typing import Self

import numpy as np
import pandas as pd

from pir_pipeline.utils.MySQLUtils import MySQLUtils


class PIRIngestor:
    def __init__(
        self, workbook: str | os.PathLike, db_config: dict, databases: list[str]
    ):
        """Initialize a PIRIngestor object

        Args:
            workbook (str|os.PathLike): File path to an Excel Workbook
        """
        self._data: dict[pd.DataFrame] = {}
        self._sql = MySQLUtils(**db_config)
        self._databases = databases

        self._workbook = workbook

    def make_snake_name(self, name: str) -> str:
        snake_name = re.sub(r"\W", "_", name.lower())
        snake_name = re.sub(r"_+", "_", snake_name)
        return snake_name

    def duplicated_question_error(
        self, df: pd.DataFrame, columns: list[str]
    ) -> pd.DataFrame:
        df.sort_values(columns + ["question_order"], inplace=True)
        df = df.groupby(columns).sample(1).reset_index().drop(columns="index")
        return df

    def missing_question_error(
        self, response: pd.DataFrame, question: pd.DataFrame, missing_questions: set
    ) -> pd.DataFrame:
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
        if not isinstance(question_number, str):
            return ""

        section = re.search("^([A-Z])", question_number)
        if section:
            return section.group(1)

        return ""

    def hash_columns(self, row: pd.Series) -> str:
        string = "".join([str(item) for item in row])
        byte_string = string.encode()

        return hashlib.md5(byte_string).hexdigest()

    def extract_sheets(self) -> Self:
        """Load the workbook, and extract sheets and year."""
        self._year = re.search(r"(\d{4})\.(csv|xlsx?)$", self._workbook).group(1)
        self._workbook = pd.ExcelFile(self._workbook)
        self._sheets = self._workbook.sheet_names
        return self

    def load_data(self) -> Self:
        for sheet in self._sheets:
            name = self.make_snake_name(sheet)
            section_condition = sheet.find("Section") > -1
            reference_condition = sheet == "Reference"
            program_condition = sheet.find("Program") > -1
            if not (section_condition or reference_condition or program_condition):
                continue

            df = pd.read_excel(self._workbook, sheet)

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
                df = df.iloc[2:, :]
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

        self._sql.make_db_connections(self._databases).get_schemas(
            "pir_data", ["response", "program", "question"]
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

        # Program
        program = self._data["program"]
        program.rename(
            columns={
                "program_zip1": "program_zip_code",
                "program_zip2": "program_zip_4",
                "program_phone": "program_main_phone_number",
                "program_email": "program_main_email",
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

        self._sql.close_db_connections()

    def ingest(self):
        (
            self.extract_sheets()
            .load_data()
            .append_sections()
            .merge_response_question()
            .clean_pir_data()
        )

        return self


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

        PIRIngestor(
            os.path.join(INPUT_DIR, file), db_config, databases=["pir_data"]
        ).ingest()
