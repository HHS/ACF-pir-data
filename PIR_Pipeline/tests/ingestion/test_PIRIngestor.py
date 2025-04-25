import random
import re
from datetime import datetime
from string import ascii_uppercase
from unittest.mock import ANY, MagicMock

import numpy as np
import pandas as pd
import pytest


class TestPIRIngestor:
    def test_make_snake_name(self, dummy_ingestor, invalid_names, valid_name):
        for n in invalid_names:
            with pytest.raises(AssertionError):
                dummy_ingestor.make_snake_name(n)

        value = dummy_ingestor.make_snake_name(valid_name)
        assert re.search(r"\W", value) is None, "Output still contains whitespace."

    def test_duplicate_question_error(self, dummy_ingestor, mock_question_data):
        columns = ["question_name", "question_number"]
        df = pd.DataFrame.from_dict(mock_question_data["raw"])
        df = dummy_ingestor.duplicated_question_error(df, columns)
        question_order = [1, 3, 4, 5]
        assert (
            df["question_order"].tolist() == question_order
        ), "Incorrect question_order"
        assert (
            not df[columns].duplicated().any()
        ), f"Data frame contains duplicates on {columns}"

    def test_get_section(self, dummy_ingestor):
        letters = [random.choice(ascii_uppercase) for i in range(20)]
        question_numbers = [letter + str(i) for i, letter in enumerate(letters)]

        correct = letters + [None, None]
        question_numbers += [1, "wrong_format"]

        result = []
        for qn in question_numbers:
            result.append(dummy_ingestor.get_section(qn))

        assert correct == result, "Incorrect string(s) returned"

    def test_hash_columns(self, dummy_ingestor, valid_hash_rows, invalid_hash_rows):
        def row_raises_assertion(df):
            for index, row in df.iterrows():
                with pytest.raises(AssertionError):
                    dummy_ingestor.hash_columns(row)

        def row_passes(df, expected_hashes):
            for (_, row), expected in zip(df.iterrows(), expected_hashes):
                assert dummy_ingestor.hash_columns(row) == expected

        row_passes(valid_hash_rows["uid_rows"], valid_hash_rows["expected_uid_hashes"])
        row_passes(valid_hash_rows["qid_rows"], valid_hash_rows["expected_qid_hashes"])

        row_raises_assertion(invalid_hash_rows["uid_rows"])
        row_raises_assertion(invalid_hash_rows["qid_rows"])
        row_raises_assertion(invalid_hash_rows["empty_row"])

    def test_stringify(self, dummy_ingestor):
        data = [
            ("test", "test", "String input should remain unchanged."),
            (
                datetime(2020, 1, 1),
                "01/01/2020",
                "Datetime input shoudl be formatted as MM/DD/YYYY.",
            ),
            (3.14159, "3.14159", "Float input should be converted to a string."),
            (1, "1", "Int input should be converted to a string."),
            (np.nan, "nan", "`np.nan` input should return 'nan' string."),
            (None, None, "`None` should be returned unchanged."),
            ("", "", "Empty string should be returned unchanged."),
            (True, True, "Empty string should be returned unchanged."),
        ]

        for value, expected, error_message in data:
            result = dummy_ingestor.stringify(value)
            if expected in [True, None]:
                assert result is expected, error_message
            else:
                assert result == expected, error_message

    @pytest.mark.parametrize("data_ingestor", [True], indirect=True)
    def test_extract_sheets(self, data_ingestor, dummy_ingestor):
        with pytest.raises(AssertionError):
            dummy_ingestor.extract_sheets()

        data_ingestor.extract_sheets()
        assert data_ingestor._year == 2008, "Year is incorrect"
        assert isinstance(
            data_ingestor._workbook, pd.ExcelFile
        ), "Workbook is not of type pd.ExcelFile"
        assert data_ingestor._sheets == [
            "Section A",
            "Section B",
            "Section C",
            "Section D",
            "Program Details",
            "Reference",
        ], "Incorrect sheets returned"

    @pytest.mark.parametrize("data_ingestor", [False], indirect=True)
    def test_load_data_with_invalid_data(self, data_ingestor):

        with pytest.raises(AssertionError):
            data_ingestor.extract_sheets().load_data()

    @pytest.mark.parametrize("data_ingestor", [True], indirect=True)
    def test_load_data_with_valid_data(self, data_ingestor):
        data_ingestor.extract_sheets().load_data()
        assert (
            not data_ingestor._data["question"][["question_number", "question_name"]]
            .duplicated()
            .any()
        ), "Unexpected duplicate values in _data['question'][['question_name', 'question_number']]"

        expected_keys = [
            "section_a",
            "section_b",
            "section_c",
            "section_d",
            "program",
            "question",
        ]
        assert [
            "section_a",
            "section_b",
            "section_c",
            "section_d",
            "program",
            "question",
        ] == list(
            data_ingestor._data.keys()
        ), f"Output dict_keys of load_data doesn't match expected keys {expected_keys}"

        # modified from gpt
        for df_name, df in data_ingestor._data.items():
            assert not df.empty, f"{df_name} DataFrame is empty."

            for col in df.columns:
                snake_col = re.sub(r"\W", "_", col.lower())
                snake_col = re.sub(r"_+", "_", snake_col)
                assert (
                    col == snake_col
                ), f"Column '{col}' in DataFrame '{df_name}' is not in snake_case."

    @pytest.mark.parametrize("data_ingestor", [True], indirect=True)
    def test_append_sections(self, data_ingestor):
        data_ingestor.extract_sheets().load_data().append_sections()
        df = data_ingestor._data["response"]
        expected_row_count = (
            data_ingestor._metrics["program"]["record_count"]
            * data_ingestor._metrics["question"]["record_count"]
        )
        assert df.shape == (expected_row_count, 14)
        assert df.columns.tolist() == [
            "region",
            "state",
            "grant_number",
            "program_number",
            "type",
            "grantee",
            "program",
            "city",
            "zip_code",
            "zip_4",
            "question_number",
            "answer",
            "question_name",
            "section",
        ]
        assert all([name.find("section") == -1 for name in data_ingestor._data])

    @pytest.mark.parametrize("data_ingestor", [True], indirect=True)
    def test_clean_pir_data(self, data_ingestor, mock_columns):
        data_ingestor._sql.get_columns = MagicMock(side_effect=mock_columns)
        (
            data_ingestor.extract_sheets()
            .load_data()
            .append_sections()
            .merge_response_question()
            .clean_pir_data()
        )
        assert list(data_ingestor._data.keys()) == [
            "program",
            "question",
            "response",
        ], "Incorrect keys in data dictionary"
        for table in ["response", "program", "question"]:
            assert data_ingestor._data[table].columns.tolist() == getattr(
                self, f"{table}_fields"
            )

    @pytest.mark.parametrize("data_ingestor", [True], indirect=True)
    def test_insert_data(self, data_ingestor, db_columns, mock_question_data):
        data_ingestor._columns = db_columns
        data_ingestor._sql.insert_records = MagicMock()
        data_ingestor._sql.update_records = MagicMock()
        question = pd.DataFrame.from_dict(mock_question_data["db"])
        data_ingestor._sql.get_records = MagicMock(return_value=question)
        (
            data_ingestor.extract_sheets()
            .load_data()
            .append_sections()
            .merge_response_question()
            .clean_pir_data()
            .insert_data()
        )

        assert data_ingestor._sql.insert_records.call_count == 3
        data_ingestor._sql.insert_records.assert_any_call(ANY, "response")
        data_ingestor._sql.insert_records.assert_any_call(ANY, "program")
        data_ingestor._sql.insert_records.assert_any_call(ANY, "question")


if __name__ == "__main__":
    pytest.main([__file__, "-sk", "test_clean_pir_data"])
