import hashlib
from unittest.mock import MagicMock

import pandas as pd
import pytest

from pir_pipeline.ingestion.PIRIngestor import PIRIngestor
from pir_pipeline.utils.MockData import MockData


@pytest.fixture
def dummy_ingestor():
    return PIRIngestor("", MagicMock())


@pytest.fixture
def data_ingestor(request: bool, tmp_path):
    mock_data = MockData(2008, valid=request.param)

    mock_data.generate_data()
    mock_data.export(directory=tmp_path)

    yield PIRIngestor(mock_data.path, MagicMock())


@pytest.fixture
def invalid_names():
    return ["   ", int(8)]


@pytest.fixture
def valid_name():
    return "Section A"


@pytest.fixture
def mock_question_data():
    question = {
        "question_number": {0: "A.1", 1: "A.1", 2: "A.2", 3: "A.3", 4: "A.4", 5: "A.3"},
        "question_name": {0: "Q1", 1: "Q1", 2: "Q2", 3: "Q3", 4: "Q4", 5: "Q3"},
        "question_order": {i: i + 1 for i in range(6)},
    }

    question_db = {
        "question_id": {
            i: value
            for i, value in enumerate(
                ["A", "A", "B", "B", "C", "C", "D", "D", "E", "E"]
            )
        },
        "uqid": {i: "" for i in range(10)},
        "question_name": {i: "" for i in range(10)},
        "question_order": {i: "" for i in range(10)},
        "question_text": {i: "" for i in range(10)},
        "question_number": {i: "" for i in range(10)},
        "question_type": {i: "" for i in range(10)},
        "section": {i: "" for i in range(10)},
    }

    question_linked = {
        "question_id": {i: value for i, value in enumerate(["A", "B", "C", "D", "E"])},
        "uqid": {i: "" for i in range(5)},
        "question_name": {i: "" for i in range(5)},
        "question_order": {i: "" for i in range(5)},
        "question_text": {i: "" for i in range(5)},
        "question_number": {i: "" for i in range(5)},
        "question_type": {i: "" for i in range(5)},
        "section": {i: "" for i in range(5)},
        "linked_id": {i: value for i, value in enumerate(["A", "B", "F", "G", "H"])},
    }

    question_unlinked = {
        "question_id": {i: value for i, value in enumerate(["A", "B", "C", "D", "E"])},
        "uqid": {i: None for i in range(5)},
        "question_name": {i: "" for i in range(5)},
        "question_order": {i: "" for i in range(5)},
        "question_text": {i: "" for i in range(5)},
        "question_number": {i: "" for i in range(5)},
        "question_type": {i: "" for i in range(5)},
        "section": {i: "" for i in range(5)},
        "linked_id": {i: value for i, value in enumerate([None])},
    }

    question_merge_pass = {
        "question_number": {i: "A." + str(i + 1) for i in range(6)},
        "question_name": {x: "Q" + str(x + 1) for x in range(6)},
        "section": {i: "A" for i in range(6)},
    }

    question_merge_fail = {
        "question_number": {i: "A." + str(i + 1) for i in range(6)},
        "question_name": {x: "Q" + str(x + 1) for x in range(6)},
        "fail": {i: "A" for i in range(6)},
    }

    question_dict = {
        "raw": question,
        "db": question_db,
        "linked": question_linked,
        "unlinked": question_unlinked,
        "question": question,
        "question_merge_pass": question_merge_pass,
        "question_merge_fail": question_merge_fail,
    }

    return question_dict


@pytest.fixture
def valid_hash_rows():

    uid_rows = pd.DataFrame(
        {
            "grant_number": ["06CH010420", "02HP0026", "05CH8368"],
            "program_number": ["000", "200", "000"],
            "program_type": ["HS", "EHS", "HS"],
        }
    )

    expected_uid_hashes = uid_rows.apply(
        lambda x: hashlib.sha1("".join(x).encode()).hexdigest(), axis=1
    ).tolist()

    qid_rows = pd.DataFrame(
        {
            "question_name": ["English", "Homeless Families Served"],
            "question_number": ["A.21.a", "C.49"],
        }
    )

    expected_qid_hashes = qid_rows.apply(
        lambda x: hashlib.sha1("".join(x).encode()).hexdigest(), axis=1
    ).tolist()

    return {
        "uid_rows": uid_rows,
        "expected_uid_hashes": expected_uid_hashes,
        "qid_rows": qid_rows,
        "expected_qid_hashes": expected_qid_hashes,
    }


@pytest.fixture
def invalid_hash_rows():

    uid_rows = pd.DataFrame(
        {"grant_number": [None], "program_number": [None], "program_type": [None]}
    )

    qid_rows = pd.DataFrame({"question_name": [None], "question_number": [None]})

    empty_row = pd.DataFrame(pd.Series([]))

    return {"uid_rows": uid_rows, "qid_rows": qid_rows, "empty_row": empty_row}


@pytest.fixture
def mock_response_data():
    response_merge_pass = {
        "question_number": {i: "A." + str(i + 1) for i in range(7)},
        "question_name": {x: "Q" + str(x + 1) for x in range(7)},
        "section": {i: "A" for i in range(7)},
    }

    response_merge_fail = {
        "question_number": {i: "A." + str(i + 1) for i in range(7)},
        "question_name": {x: "Q" + str(x + 1) for x in range(7)},
        "fail": {i: "A" for i in range(7)},
    }

    return {
        "response_merge_pass": response_merge_pass,
        "response_merge_fail": response_merge_fail,
    }


@pytest.fixture
def mock_missing_questions():
    return "A.7"


# Adapted from GPT
@pytest.fixture
def mock_columns(request, program_columns, question_columns, response_columns):
    response_fields = list(response_columns)

    program_fields = list(program_columns)

    question_fields = list(question_columns)

    request.cls.response_fields = response_fields
    request.cls.program_fields = program_fields
    request.cls.question_fields = question_fields

    columns = {
        "response": response_fields,
        "question": question_fields,
        "program": program_fields,
    }

    return columns.get
