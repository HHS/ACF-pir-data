import pytest

from pir_pipeline.config import db_config
from pir_pipeline.utils.MockData import MockData
from pir_pipeline.utils.SQLAlchemyUtils import SQLAlchemyUtils


@pytest.fixture(scope="module")
def sql_utils(request):
    try:
        sql = SQLAlchemyUtils(**db_config, database="pir_test")
        request.module.drivername = "mysql+mysqlconnector"
    except Exception:
        sql = SQLAlchemyUtils(
            **db_config, database="pir_test", drivername="postgresql+psycopg"
        )
        request.module.drivername = "postgresql+psycopg"

    return sql


@pytest.fixture
def mock_data():
    mock_data = MockData
    return mock_data


@pytest.fixture(scope="module")
def create_database(sql_utils):
    sql_utils.create_db()
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


@pytest.fixture
def response_columns():
    return {"uid", "question_id", "year", "answer"}


@pytest.fixture
def program_columns():
    return {
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
    }


@pytest.fixture
def db_columns(program_columns, question_columns, response_columns):
    db_columns = {
        "program": program_columns,
        "question": question_columns,
        "response": response_columns,
    }

    return db_columns
