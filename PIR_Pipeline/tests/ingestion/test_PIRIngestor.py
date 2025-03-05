import os
import random
from string import ascii_uppercase

import pandas as pd
import pytest

if __name__ == "__main__":
    from question import question
else:
    from .question import question

from pir_pipeline.ingestion.PIRIngestor import PIRIngestor


@pytest.fixture
def dummy_ingestor():
    return PIRIngestor(
        "", {"user": "", "password": "", "host": "", "port": ""}, database="pir"
    )


@pytest.fixture
def data_ingestor():
    return PIRIngestor(
        os.path.join(os.path.dirname(__file__), "test_data_2008.xlsx"),
        {"user": "", "password": "", "host": "", "port": ""},
        database="pir",
    )


class TestPIRIngestor:
    def test_duplicate_question_error(self, dummy_ingestor):
        columns = ["question_name", "question_number"]
        df = pd.DataFrame.from_dict(question)
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


if __name__ == "__main__":
    pytest.main([__file__, "-s"])
