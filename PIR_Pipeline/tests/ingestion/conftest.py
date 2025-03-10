import os
from unittest.mock import MagicMock

import pandas as pd
import pytest

from pir_pipeline.ingestion.PIRIngestor import PIRIngestor


@pytest.fixture
def dummy_ingestor():
    return PIRIngestor(
        "",
        MagicMock(),
        database="pir",
    )


@pytest.fixture
def data_ingestor():
    return PIRIngestor(
        os.path.join(os.path.dirname(__file__), "test_data_2008.xlsx"),
        MagicMock(),
        database="pir",
    )

@pytest.fixture
def invalid_names():
    return ['   ', int(8)]

@pytest.fixture
def valid_name():
    return 'Section A'

@pytest.fixture
def mock_question_data():
    question = {
        "question_number": {0: "A.1", 1: "A.1", 2: "A.2", 3: "A.3", 4: "A.4", 5: "A.3"},
        "question_name": {0: "Q1", 1: "Q1", 2: "Q2", 3: "Q3", 4: "Q4", 5: "Q3"},
        "question_order": {i: i + 1 for i in range(6)},
    }
    
    question_merge_pass = {
        "question_number": {i: "A." + str(i + 1) for i in range(6)},
        "question_name": {x: 'Q' + str(x + 1) for x in range(6)},
        "section": {i: "A" for i in range(6)}
    }
    
    question_merge_fail = {
        "question_number": {i: "A." + str(i + 1) for i in range(6)},
        "question_name": {x: 'Q' + str(x + 1) for x in range(6)},
        "fail": {i: "A" for i in range(6)}
    }

    return {
        "question" : question,
        "question_merge_pass" : question_merge_pass,
        "question_merge_fail" : question_merge_fail
    }

@pytest.fixture
def mock_response_data():
    response_merge_pass = {
        "question_number": {i: "A." + str(i + 1) for i in range(7)},
        "question_name": {x: 'Q' + str(x + 1) for x in range(7)},
        "section": {i: "A" for i in range(7)}
    }
    
    response_merge_fail = {
        "question_number": {i: "A." + str(i + 1) for i in range(7)},
        "question_name": {x: 'Q' + str(x + 1) for x in range(7)},
        "fail": {i: "A" for i in range(7)}
    }
    
    return {
        "response_merge_pass" : response_merge_pass,
        "response_merge_fail" : response_merge_fail
    }

@pytest.fixture
def mock_missing_questions():
    return 'A.7'

# Adapted from GPT
@pytest.fixture
def mock_schemas(request):
    def create_schema(fields):
        num_fields = len(fields)
        schema = {
            "Field": {i: field for i, field in enumerate(fields)},
            "Type": {i: "" for i in range(num_fields)},
            "Null": {i: "" for i in range(num_fields)},
            "Key": {i: "" for i in range(num_fields)},
            "Default": {i: "" for i in range(num_fields)},
            "Extra": {i: "" for i in range(num_fields)},
        }
        return schema

    response_fields = ["uid", "question_id", "year", "answer"]
    response = create_schema(response_fields)

    program_fields = [
        "uid",
        "year",
        "grantee_name",
        "grant_number",
        "program_address_line_1",
        "program_address_line_2",
        "program_agency_description",
        "program_agency_type",
        "program_city",
        "program_email",
        "program_name",
        "program_number",
        "program_phone",
        "program_type",
        "program_state",
        "program_zip1",
        "program_zip2",
        "region",
    ]
    program = create_schema(program_fields)

    question_fields = [
        "question_id",
        "year",
        "uqid",
        "category",
        "question_name",
        "question_number",
        "question_order",
        "question_text",
        "question_type",
        "section",
        "subsection",
    ]
    question = create_schema(question_fields)

    schemas = {
        "response": pd.DataFrame.from_dict(response),
        "program": pd.DataFrame.from_dict(program),
        "question": pd.DataFrame.from_dict(question),
    }

    request.cls.response_fields = response_fields
    request.cls.program_fields = program_fields
    request.cls.question_fields = question_fields

    return schemas
