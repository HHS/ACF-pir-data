import random
from string import ascii_uppercase
from unittest.mock import MagicMock

import pandas as pd
import pytest


class TestPIRIngestor:
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
    pytest.main([__file__, "-s"])
