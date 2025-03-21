import pandas as pd
import pytest

from pir_pipeline.config import db_config
from pir_pipeline.utils.MockData import MockData
from pir_pipeline.utils.SQLAlchemyUtils import SQLAlchemyUtils


@pytest.fixture(scope="module")
def sql_utils():
    sql = SQLAlchemyUtils(**db_config, database="pir_test")
    return sql


@pytest.fixture(scope="class")
def mock_data():
    mock_data = MockData()
    mock_data.generate_data().export(pandas=True)


@pytest.fixture(scope="class")
def create_database(sql_utils, question_records):
    sql_utils.create_db()
    sql_utils.insert_records(question_records, "question")
    yield
    sql_utils.drop_db()


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
