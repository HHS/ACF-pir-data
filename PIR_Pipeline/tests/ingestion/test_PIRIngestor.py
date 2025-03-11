import random
from string import ascii_uppercase
from datetime import datetime
from unittest.mock import MagicMock
import numpy as np
import pandas as pd
import pytest
import re


class TestPIRIngestor:
    def test_make_snake_name(self, dummy_ingestor, invalid_names, valid_name): 
        for n in invalid_names:
            with pytest.raises(AssertionError):
                dummy_ingestor.make_snake_name(n)
                
        value = dummy_ingestor.make_snake_name(valid_name)
        assert re.search("\W", value) is None, "Output still contains whitespace."
    
    def test_missing_question_error(self, dummy_ingestor, mock_question_data, mock_response_data, mock_missing_questions):

        mock_missing_questions = set(mock_response_data["response_merge_fail"]) - set(mock_question_data["question_merge_fail"])
        
        with pytest.raises(AssertionError):
            dummy_ingestor.missing_question_error(mock_response_data["response_merge_fail"], mock_question_data["question_merge_fail"], mock_missing_questions)
        
        mock_question_data = pd.DataFrame.from_dict(mock_question_data["question_merge_pass"])
        mock_response_data = pd.DataFrame.from_dict(mock_response_data["response_merge_pass"])
        mock_missing_questions = set(mock_response_data["question_number"]) - set(mock_question_data["question_number"])
        
        expected_numrows = mock_question_data.shape[0] + len(mock_missing_questions)
        
        value = dummy_ingestor.missing_question_error(mock_response_data, mock_question_data, mock_missing_questions)
        
        assert value.shape[0] == expected_numrows, f"Output of mock_missing_question_error is an incorrect length. Expected {expected_numrows}."
        assert isinstance(value, pd.DataFrame), "Output of mock_missing_question_error is not type pd.DataFrame."
        assert mock_missing_questions.issubset(set(value["question_number"])), "Missing question not added to value."

        
    def test_duplicate_question_error(self, dummy_ingestor, mock_question_data):
        columns = ["question_name", "question_number"]
        df = pd.DataFrame.from_dict(mock_question_data)
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

        correct = letters + ["", ""]
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

        row_passes(valid_hash_rows['uid_rows'], valid_hash_rows['expected_uid_hashes'])
        row_passes(valid_hash_rows['qid_rows'], valid_hash_rows['expected_qid_hashes'])

        row_raises_assertion(invalid_hash_rows['uid_rows'])
        row_raises_assertion(invalid_hash_rows['qid_rows'])
        row_raises_assertion(invalid_hash_rows['empty_row'])
        
    def test_stringify(self, dummy_ingestor):
        
        result = dummy_ingestor.stringify("test")
        assert result == "test", "String input should remain unchanged."

        date = datetime(2020, 1, 1)
        result = dummy_ingestor.stringify(date)
        assert result == "01/01/2020", "Datetime input shoudl be formatted as MM/DD/YYYY."

        result = dummy_ingestor.stringify(3.14159)
        assert result == "3.14159", "Float input should be converted to a string."
        
        result = dummy_ingestor.stringify(1)
        assert result == "1", "Int input should be converted to a string."
        
        result = dummy_ingestor.stringify(np.nan)
        assert result == 'nan', "`np.nan` input should return 'nan' string."
        
        result = dummy_ingestor.stringify(None)
        assert result is None, "`None` should be returned unchanged."
        
        result = dummy_ingestor.stringify("")
        assert result == "", "Empty string should be returned unchanged."
        
        result = dummy_ingestor.stringify(True)
        assert result == True, "Boolean input should be returned unchanged."
        
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

    def test_append_sections(self, data_ingestor):
        data_ingestor.extract_sheets().load_data().append_sections()
        df = data_ingestor._data["response"]
        assert df.shape == (80, 14)
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

    def test_clean_pir_data(self, data_ingestor, mock_schemas):
        data_ingestor._sql._schemas = mock_schemas
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


if __name__ == "__main__":
    pytest.main([__file__, "-sk", "stringify"])
