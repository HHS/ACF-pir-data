import os
import re

import pandas as pd

from pir_pipeline.utils.paths import INPUT_DIR


class PIRIngestor:
    def __init__(self, workbook: str | os.PathLike):
        """Initialize a PIRIngestor object

        Args:
            workbook (str|os.PathLike): File path to an Excel Workbook
        """
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

    def get_section(self, question_number: str):
        return re.search("^([A-Z])", question_number).group(1)

    def extract_sheets(self):
        """Load the workbook, and extract sheets and year."""
        self._year = re.search(r"(\d{4})\.(csv|xlsx?)$", self._workbook).group(1)
        self._workbook = pd.ExcelFile(self._workbook)
        self._sheets = self._workbook.sheet_names
        return self

    def load_data(self):
        self._data = {}
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
                        column_name + f"_{duplicated_names[column_name]}"
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

            df.columns = df.columns.map(self.make_snake_name)
            self._data[name] = df

        return self

    def append_sections(self):
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

    def merge_response_question(self):
        # Response data
        def gen_lower_question_number(string: str):
            string = string.lower().strip()
            return "na" if re.search(r"^n/a|n\\.?a\\.?$", string) else string

        response = self._data["response"]
        response["question_number"] = response["question_number"].map(
            lambda x: re.sub(r"_\d+$", "", x)
        )
        response["q_num_lower"] = response["question_number"].map(
            gen_lower_question_number
        )

        # Question data
        question = self._data["reference"]
        self._data["question"] = self._data["reference"]
        del self._data["reference"]

        # Confirm all questions are in question
        missing_questions = set(response["question_number"]) - set(
            question["question_number"]
        )
        assert (
            missing_questions == set()
        ), f"Some questions are missing: {missing_questions}"

        # Merge
        response = response.merge(
            question,
            how="left",
            on=["question_number", "question_name"],
            validate="many_to_one",
            indicator=True,
        )

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

    def ingest(self):
        self.extract_sheets().load_data().append_sections().merge_response_question()


if __name__ == "__main__":
    PIRIngestor(os.path.join(INPUT_DIR, "pir_export_2023.xlsx")).ingest()
