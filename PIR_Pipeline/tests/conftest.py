import pytest

from pir_pipeline.config import DB_CONFIG
from pir_pipeline.utils.MockData import MockData
from pir_pipeline.utils.SQLAlchemyUtils import SQLAlchemyUtils


@pytest.fixture(scope="session")
def error_message_constructor(message: str, expected=None, got=None):
    expected_got = []
    if expected:
        expected_got.append(f"Expected {expected}")

    if got:
        expected_got.append(f"Got {got}")

    if expected_got:
        message = f"{message}: {'; '.join(expected_got)}"

    return message


@pytest.fixture(scope="module")
def insert_question_records(sql_utils, question_linker_records):
    sql_utils.insert_records(question_linker_records, "question")


@pytest.fixture(scope="module")
def sql_utils(request):
    sql = SQLAlchemyUtils(**DB_CONFIG, database="pir_test")

    if sql.engine.dialect.name == "mysql":
        request.module.drivername = "mysql+mysqlconnector"
    else:
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


@pytest.fixture(scope="module")
def question_linker_records():
    return [
        {  # 2023-2024 link
            "question_id": "42d3b624c74d07c3a574a4f26fa3c686",
            "year": 2023,
            "uqid": "194ed0fc57877f9ee8eee0fc5927b148",
            "category": "Program Staff and Qualifications",
            "question_name": "Of the number of education and child development staff that left, the number that left for the following primary reason - Other - Specify Text",
            "question_number": "B.18.d-1",
            "question_order": 107.40005000000001,
            "question_text": "Other (e.g., change in job field, reason not provided)",
            "question_type": "Text",
            "section": "B",
            "subsection": None,
        },
        {
            "question_id": "0686c2ad4d3041b580a1d4015b9f0c80",
            "year": 2024,
            "uqid": "194ed0fc57877f9ee8eee0fc5927b148",
            "category": "Program Staff and Qualifications",
            "question_name": "Of the number of education and child development staff that left, the number that left for the following primary reason - Other - Text",
            "question_number": "B.18.d-1",
            "question_order": 107.40005000000001,
            "question_text": "Other (e.g., change in job field, reason not provided)",
            "question_type": "Text",
            "section": "B",
            "subsection": None,
        },
        {  # intermittent link
            "question_id": "4167b6decdcd59db40b69e0fba43e7f0",
            "year": 2009,
            "uqid": "00517751cc2f7920185e52926ce7a0c9",
            "category": "Program Information",
            "question_name": "Other Languages",
            "question_number": "A.21.k-1",
            "question_order": 59.0,
            "question_text": "Other (e.g., American Sign Language)",
            "question_type": "Text",
            "section": "A",
            "subsection": "Primary Language of Family at Home",
        },
        {
            "question_id": "4167b6decdcd59db40b69e0fba43e7f0",
            "year": 2008,
            "uqid": "00517751cc2f7920185e52926ce7a0c9",
            "category": "Program Information",
            "question_name": "Other Languages",
            "question_number": "A.21.k-1",
            "question_order": 59.0,
            "question_text": "Other (e.g., American Sign Language)",
            "question_type": "Text",
            "section": "A",
            "subsection": "Primary Language of Family at Home",
        },
        {
            "question_id": "4167b6decdcd59db40b69e0fba43e7f0",
            "year": 2010,
            "uqid": "00517751cc2f7920185e52926ce7a0c9",
            "category": "Program Information",
            "question_name": "Other Languages",
            "question_number": "A.21.k-1",
            "question_order": 59.0,
            "question_text": "Other (e.g., American Sign Language)",
            "question_type": "Text",
            "section": "A",
            "subsection": "Primary Language of Family at Home",
        },
        {
            "question_id": "7bfb25407153bbbb171e5d2280c1194f",
            "year": 2011,
            "uqid": "00517751cc2f7920185e52926ce7a0c9",
            "category": "Program Information",
            "question_name": "Other Languages",
            "question_number": "A.22.k-1",
            "question_order": 59.0,
            "question_text": "Other (e.g., American Sign Language)",
            "question_type": "Text",
            "section": "A",
            "subsection": "Primary Language of Family at Home",
        },
        {
            "question_id": "94287f7374fca04143dd9cca42b05e4c",
            "year": 2015,
            "uqid": "00517751cc2f7920185e52926ce7a0c9",
            "category": "Program Information",
            "question_name": "Other Languages",
            "question_number": "A.27.k-1",
            "question_order": 59.00005,
            "question_text": "Other (e.g., American Sign Language)",
            "question_type": "Text",
            "section": "A",
            "subsection": None,
        },
        {  # another intermittent link with two series to link together
            "question_id": "6b2522aa7ff248ca4d80ac299104ca2e",
            "year": 2015,
            "uqid": "5ff5919440ca5dcd4c9dbda1eff168d4",
            "category": "Program Information",
            "question_name": "MIS Locally Designed 3",
            "question_number": "A.31.c-2",
            "question_order": 80.8,
            "question_text": "MIS Locally Designed 3",
            "question_type": "Text",
            "section": "A",
            "subsection": None,
        },
        {
            "question_id": "6b2522aa7ff248ca4d80ac299104ca2e",
            "year": 2016,
            "uqid": "5ff5919440ca5dcd4c9dbda1eff168d4",
            "category": "Program Information",
            "question_name": "MIS Locally Designed 3",
            "question_number": "A.31.c-2",
            "question_order": 80.8,
            "question_text": "MIS Locally Designed 3",
            "question_type": "Text",
            "section": "A",
            "subsection": None,
        },
        {
            "question_id": "6b2522aa7ff248ca4d80ac299104ca2e",
            "year": 2017,
            "uqid": "5ff5919440ca5dcd4c9dbda1eff168d4",
            "category": "Program Information",
            "question_name": "MIS Locally Designed 3",
            "question_number": "A.31.c-2",
            "question_order": 80.8,
            "question_text": "MIS Locally Designed 3",
            "question_type": "Text",
            "section": "A",
            "subsection": None,
        },
        {
            "question_id": "6b2522aa7ff248ca4d80ac299104ca2e",
            "year": 2018,
            "uqid": "5ff5919440ca5dcd4c9dbda1eff168d4",
            "category": "Program Information",
            "question_name": "MIS Locally Designed 3",
            "question_number": "A.31.c-2",
            "question_order": 80.8,
            "question_text": "MIS Locally Designed 3",
            "question_type": "Text",
            "section": "A",
            "subsection": None,
        },
        {
            "question_id": "6b2522aa7ff248ca4d80ac299104ca2e",
            "year": 2019,
            "uqid": "5ff5919440ca5dcd4c9dbda1eff168d4",
            "category": "Program Information",
            "question_name": "MIS Locally Designed 3",
            "question_number": "A.31.c-2",
            "question_order": 80.8,
            "question_text": "MIS Locally Designed 3",
            "question_type": "Text",
            "section": "A",
            "subsection": None,
        },
        {
            "question_id": "3dc2c6572e8b64ffd64231c43ccd95d6",
            "year": 2012,
            "uqid": "0b19c17c60bfce95f963a1ddc0575588",
            "category": "Program Information",
            "question_name": "MIS Locally Designed 3",
            "question_number": "A.30.c-2",
            "question_order": 87.0,
            "question_text": "Enter name/title, if locally designed, and if web-based",
            "question_type": "Text",
            "section": "A",
            "subsection": "Management Information Systems",
        },
        {
            "question_id": "3dc2c6572e8b64ffd64231c43ccd95d6",
            "year": 2013,
            "uqid": "0b19c17c60bfce95f963a1ddc0575588",
            "category": "Program Information",
            "question_name": "MIS Locally Designed 3",
            "question_number": "A.30.c-2",
            "question_order": 87.0,
            "question_text": "Enter name/title, if locally designed, and if web-based",
            "question_type": "Text",
            "section": "A",
            "subsection": "Management Information Systems",
        },
        {
            "question_id": "3dc2c6572e8b64ffd64231c43ccd95d6",
            "year": 2014,
            "uqid": "0b19c17c60bfce95f963a1ddc0575588",
            "category": "Program Information",
            "question_name": "MIS Locally Designed 3",
            "question_number": "A.30.c-2",
            "question_order": 87.0,
            "question_text": "Enter name/title, if locally designed, and if web-based",
            "question_type": "Text",
            "section": "A",
            "subsection": "Management Information Systems",
        },
        {  # unlinked with likely intermittent to link to
            "question_id": "83e32d72b46030e1abf5109b8b506fb8",
            "year": 2011,
            "uqid": None,
            "category": "Staff",
            "question_name": "Total Preschool Family Child Care Providers",
            "question_number": "B.5-4",
            "question_order": 254.0,
            "question_text": "Total number of preschool child development staff by position - Family Child Care Providers",
            "question_type": "Number",
            "section": "B",
            "subsection": "Preschool Child Development Staff - Qualifications (HS and Migrant programs)",
        },
        {
            "question_id": "87fe124509e4e9e48b26a65b78c87acd",
            "year": 2009,
            "uqid": "8cfa414fcd9b593e45bee4dd68080ae8",
            "category": "Program Staff and Qualifications",
            "question_name": "Total Family Child Care Providers",
            "question_number": "B.5-4",
            "question_order": 188.0,
            "question_text": "Total number of child development staff by position - # of Family Child Care Providers",
            "question_type": "Number",
            "section": "B",
            "subsection": "Child Development Staff - Qualifications",
        },
        {
            "question_id": "87fe124509e4e9e48b26a65b78c87acd",
            "year": 2008,
            "uqid": "8cfa414fcd9b593e45bee4dd68080ae8",
            "category": "Program Staff and Qualifications",
            "question_name": "Total Family Child Care Providers",
            "question_number": "B.5-4",
            "question_order": 188.0,
            "question_text": "Total number of child development staff by position - # of Family Child Care Providers",
            "question_type": "Number",
            "section": "B",
            "subsection": "Child Development Staff - Qualifications",
        },
        {
            "question_id": "87fe124509e4e9e48b26a65b78c87acd",
            "year": 2010,
            "uqid": "8cfa414fcd9b593e45bee4dd68080ae8",
            "category": "Program Staff and Qualifications",
            "question_name": "Total Family Child Care Providers",
            "question_number": "B.5-4",
            "question_order": 188.0,
            "question_text": "Total number of child development staff by position - # of Family Child Care Providers",
            "question_type": "Number",
            "section": "B",
            "subsection": "Child Development Staff - Qualifications",
        },
        {
            "question_id": "0008a5809edbdca1d1141ea1f2eb8dfa",
            "year": 2021,
            "uqid": "5512c4f54e3ace4484e59cdc48976761",
            "category": "Program Information",
            "question_name": "Total Double Session Classes Operated",
            "question_number": "A.9.a",
            "question_order": 16.3,
            "question_text": "Of these, the number of double session classes",
            "question_type": "Number",
            "section": "A",
            "subsection": None,
        },
    ]


@pytest.fixture
def question_linker_payload():
    payload = {
        "1": {
            "link_type": "unlink",
            "base_question_id": "42d3b624c74d07c3a574a4f26fa3c686",
            "base_uqid": "194ed0fc57877f9ee8eee0fc5927b148",
            "match_question_id": "0686c2ad4d3041b580a1d4015b9f0c80",
            "match_uqid": "194ed0fc57877f9ee8eee0fc5927b148",
        },
        "2": {
            "link_type": "unlink",
            "base_question_id": "7bfb25407153bbbb171e5d2280c1194f",
            "base_uqid": "00517751cc2f7920185e52926ce7a0c9",
            "match_question_id": "4167b6decdcd59db40b69e0fba43e7f0",
            "match_uqid": "00517751cc2f7920185e52926ce7a0c9",
        },
        "3": {
            "link_type": "link",
            "base_question_id": "6b2522aa7ff248ca4d80ac299104ca2e",
            "base_uqid": "5ff5919440ca5dcd4c9dbda1eff168d4",
            "match_question_id": "3dc2c6572e8b64ffd64231c43ccd95d6",
            "match_uqid": "0b19c17c60bfce95f963a1ddc0575588",
        },
        "4": {
            "link_type": "link",
            "base_question_id": "83e32d72b46030e1abf5109b8b506fb8",
            "base_uqid": None,
            "match_question_id": "87fe124509e4e9e48b26a65b78c87acd",
            "match_uqid": "8cfa414fcd9b593e45bee4dd68080ae8",
        },
        "5": {
            "link_type": "confirm",
            "base_question_id": None,
            "base_uqid": "5512c4f54e3ace4484e59cdc48976761",
            "match_question_id": None,
            "match_uqid": None,
        },
    }

    return payload
