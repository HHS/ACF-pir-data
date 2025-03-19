import pandas as pd
import pytest

from pir_pipeline.config import db_config
from pir_pipeline.linking.PIRLinker import PIRLinker
from pir_pipeline.utils.SQLAlchemyUtils import SQLAlchemyUtils


@pytest.fixture(scope="module")
def sql_utils():
    sql = SQLAlchemyUtils(**db_config, database="pir_test")
    return sql


@pytest.fixture(scope="class")
def question_records():
    question_db = {
        "question_id": {
            i: value
            for i, value in enumerate(
                ["A", "A", "B", "B", "C", "C", "D", "D", "E", "E"]
            )
        },
        "year": {i: 2008 + (i % 2) for i in range(10)},
        "uqid": {i: "" for i in range(10)},
        "category": {i: "" for i in range(10)},
        "question_name": {i: "" for i in range(10)},
        "question_number": {i: "" for i in range(10)},
        "question_order": {i: 0.0 for i in range(10)},
        "question_text": {i: "" for i in range(10)},
        "question_type": {i: "" for i in range(10)},
        "section": {i: "" for i in range(10)},
        "subsection": {i: "" for i in range(10)},
    }
    records = pd.DataFrame.from_dict(question_db).to_dict(orient="records")
    return records


@pytest.fixture(scope="class")
def create_database(sql_utils, question_records):
    sql_utils.create_db()
    sql_utils.insert_records(question_records, "question")
    yield
    sql_utils.drop_db()


@pytest.fixture
def pir_linker(sql_utils, question_records):
    return PIRLinker(question_records, sql_utils)


@pytest.fixture
def question_columns():
    return {
        "question_id",
        "year",
        "category",
        "question_name",
        "question_number",
        "question_order",
        "question_text",
        "question_type",
        "section",
        "subsection",
        "uqid",
    }
