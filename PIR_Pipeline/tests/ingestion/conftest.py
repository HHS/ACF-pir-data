import os

import pytest

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


@pytest.fixture
def mock_question_data():
    question = {
        "question_number": {0: "A.1", 1: "A.1", 2: "A.2", 3: "A.3", 4: "A.4", 5: "A.3"},
        "question_name": {0: "Q1", 1: "Q1", 2: "Q2", 3: "Q3", 4: "Q4", 5: "Q3"},
        "question_order": {i: i + 1 for i in range(6)},
    }

    return question
