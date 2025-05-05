import pytest

from pir_pipeline.config import DB_CONFIG
from pir_pipeline.utils.MockData import MockData
from pir_pipeline.utils.SQLAlchemyUtils import SQLAlchemyUtils


@pytest.fixture(scope="session")
def error_message_constructor():
    def emc(message: str, expected=None, got=None):
        expected_got = []
        if expected:
            expected_got.append(f"Expected {expected}")

        if got:
            expected_got.append(f"Got {got}")

        if expected_got:
            message = f"{message}: {'; '.join(expected_got)}"

        return message

    return emc


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
        {
            "question_id": "443a354c772a24df0c2bba9acf568576a3b7d182",
            "year": 2023,
            "uqid": "6c9f2d2dcd01048e5163e12a1f50cb8e7c926e43",
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
            "question_id": "d27e8217ba30000a78e5d92ea54f4d9a2e69cb54",
            "year": 2024,
            "uqid": "6c9f2d2dcd01048e5163e12a1f50cb8e7c926e43",
            "category": "Program Staff and Qualifications",
            "question_name": "Of the number of education and child development staff that left, the number that left for the following primary reason - Other - Text",
            "question_number": "B.18.d-1",
            "question_order": 107.40005000000001,
            "question_text": "Other (e.g., change in job field, reason not provided)",
            "question_type": "Text",
            "section": "B",
            "subsection": None,
        },
        {
            "question_id": "dd089009542dfd51e45f2f23826dbc7a6f6a912e",
            "year": 2009,
            "uqid": "e358fa167d3a9d5872f563ec5cfa07898a7ee186",
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
            "question_id": "dd089009542dfd51e45f2f23826dbc7a6f6a912e",
            "year": 2008,
            "uqid": "e358fa167d3a9d5872f563ec5cfa07898a7ee186",
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
            "question_id": "dd089009542dfd51e45f2f23826dbc7a6f6a912e",
            "year": 2010,
            "uqid": "e358fa167d3a9d5872f563ec5cfa07898a7ee186",
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
            "question_id": "b5c2dd4e8fe4523405cfcd2753da583d669db2af",
            "year": 2011,
            "uqid": "e358fa167d3a9d5872f563ec5cfa07898a7ee186",
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
            "question_id": "5f50241087df4b86810c044c4777566f50ae7453",
            "year": 2015,
            "uqid": "e358fa167d3a9d5872f563ec5cfa07898a7ee186",
            "category": "Program Information",
            "question_name": "Other Languages",
            "question_number": "A.27.k-1",
            "question_order": 59.00005,
            "question_text": "Other (e.g., American Sign Language)",
            "question_type": "Text",
            "section": "A",
            "subsection": None,
        },
        {
            "question_id": "8e96da390b28ba6f5571ee1f68716cca982ccca0",
            "year": 2015,
            "uqid": "a488b1e05a2b7b462c3fafb5b6c3536704c39959",
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
            "question_id": "8e96da390b28ba6f5571ee1f68716cca982ccca0",
            "year": 2016,
            "uqid": "a488b1e05a2b7b462c3fafb5b6c3536704c39959",
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
            "question_id": "8e96da390b28ba6f5571ee1f68716cca982ccca0",
            "year": 2017,
            "uqid": "a488b1e05a2b7b462c3fafb5b6c3536704c39959",
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
            "question_id": "8e96da390b28ba6f5571ee1f68716cca982ccca0",
            "year": 2018,
            "uqid": "a488b1e05a2b7b462c3fafb5b6c3536704c39959",
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
            "question_id": "8e96da390b28ba6f5571ee1f68716cca982ccca0",
            "year": 2019,
            "uqid": "a488b1e05a2b7b462c3fafb5b6c3536704c39959",
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
            "question_id": "a01842852de3fa9893856eb711efc3e34fdc1037",
            "year": 2012,
            "uqid": "0e9fdf808ccf193218f64d62ab9b0c60f860de6b",
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
            "question_id": "a01842852de3fa9893856eb711efc3e34fdc1037",
            "year": 2013,
            "uqid": "0e9fdf808ccf193218f64d62ab9b0c60f860de6b",
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
            "question_id": "a01842852de3fa9893856eb711efc3e34fdc1037",
            "year": 2014,
            "uqid": "0e9fdf808ccf193218f64d62ab9b0c60f860de6b",
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
            "question_id": "0e93c25d3a95604f40d3a64e2298093b4faed6f2",
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
            "question_id": "66e92dd434dc3cccc5e14e3ad4ce710be8c7fb9d",
            "year": 2009,
            "uqid": "ca2fca6b6b932b8fcbf9c92b66a9605b5a5b7f81",
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
            "question_id": "66e92dd434dc3cccc5e14e3ad4ce710be8c7fb9d",
            "year": 2008,
            "uqid": "ca2fca6b6b932b8fcbf9c92b66a9605b5a5b7f81",
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
            "question_id": "66e92dd434dc3cccc5e14e3ad4ce710be8c7fb9d",
            "year": 2010,
            "uqid": "ca2fca6b6b932b8fcbf9c92b66a9605b5a5b7f81",
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
            "question_id": "8143708cc4a248c38504fbd783646557b23665df",
            "year": 2021,
            "uqid": "a5d26ad90fec036826376e3be8425e9749c7160c",
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
            "base_question_id": "443a354c772a24df0c2bba9acf568576a3b7d182",
            "base_uqid": "6c9f2d2dcd01048e5163e12a1f50cb8e7c926e43",
            "match_question_id": "d27e8217ba30000a78e5d92ea54f4d9a2e69cb54",
            "match_uqid": "6c9f2d2dcd01048e5163e12a1f50cb8e7c926e43",
        },
        "2": {
            "link_type": "unlink",
            "base_question_id": "b5c2dd4e8fe4523405cfcd2753da583d669db2af",
            "base_uqid": "e358fa167d3a9d5872f563ec5cfa07898a7ee186",
            "match_question_id": "dd089009542dfd51e45f2f23826dbc7a6f6a912e",
            "match_uqid": "e358fa167d3a9d5872f563ec5cfa07898a7ee186",
        },
        "3": {
            "link_type": "link",
            "base_question_id": "8e96da390b28ba6f5571ee1f68716cca982ccca0",
            "base_uqid": "a488b1e05a2b7b462c3fafb5b6c3536704c39959",
            "match_question_id": "a01842852de3fa9893856eb711efc3e34fdc1037",
            "match_uqid": "0e9fdf808ccf193218f64d62ab9b0c60f860de6b",
        },
        "4": {
            "link_type": "link",
            "base_question_id": "0e93c25d3a95604f40d3a64e2298093b4faed6f2",
            "base_uqid": None,
            "match_question_id": "66e92dd434dc3cccc5e14e3ad4ce710be8c7fb9d",
            "match_uqid": "ca2fca6b6b932b8fcbf9c92b66a9605b5a5b7f81",
        },
        "5": {
            "link_type": "confirm",
            "base_question_id": '8143708cc4a248c38504fbd783646557b23665df',
            "base_uqid": "a5d26ad90fec036826376e3be8425e9749c7160c",
            "match_question_id": None,
            "match_uqid": None,
        },
    }

    return payload
