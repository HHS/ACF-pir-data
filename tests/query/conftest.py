import os

import pytest

from pir_pipeline.config import DB_CONFIG
from pir_pipeline.query import create_app


@pytest.fixture(scope="module")
def app():
    test_db_config = DB_CONFIG.copy()
    test_config = {
        "TESTING": True,
        "DB_CONFIG": test_db_config,
        "DB_NAME": "pir_test",
        "SECRET_KEY": "dev",
    }
    app = create_app(
        test_config=test_config,
        template_folder=os.path.join(
            os.path.dirname(__file__),
            "..",
            "..",
            "src",
            "pir_pipeline",
            "query",
            "templates",
        ),
    )

    yield app


@pytest.fixture(scope="module")
def client(app):
    return app.test_client()


@pytest.fixture(scope="module")
def program_records():
    return [
        {
            "uid": "bce18827c769a47c13fce74785fe393bf3c6d929",
            "year": 2009,
            "grantee_name": "COMMUNITY RENEWAL TEAM OF GREATER HARTFORD",
            "grant_number": "01CH0116",
            "program_address_line_1": "555 Windsor Street",
            "program_address_line_2": None,
            "program_agency_description": "Grantee that directly operates programs and delegates service delivery",
            "program_agency_type": "Community Action Agency (CAA)",
            "program_city": "Hartford",
            "program_email": "copesp@crtct.org",
            "program_name": "Community Renewal Team, Inc. (CRT)",
            "program_number": "000",
            "program_phone": "(860) 560-5617",
            "program_type": "HS",
            "program_state": "CT",
            "program_zip1": "06120",
            "program_zip2": "2418",
            "region": 1,
        },
        {
            "uid": "c27e16e43f9feaea33441d1857989a64cd439a52",
            "year": 2011,
            "grantee_name": "UNITED WAY OF GREATER NEW HAVEN",
            "grant_number": "01CH0002",
            "program_address_line_1": "250 Cedar Street",
            "program_address_line_2": None,
            "program_agency_description": "Delegate agency",
            "program_agency_type": "Private/Public Non-Profit (Non-CAA) (e.g., church or non-profit hospital)",
            "program_city": "New Haven",
            "program_email": "magdalenar@lulacheadstart.org",
            "program_name": "LULAC Head Start, Inc.",
            "program_number": "203",
            "program_phone": "(203) 777-4006",
            "program_type": "EHS",
            "program_state": "CT",
            "program_zip1": "06519",
            "program_zip2": "1632",
            "region": 1,
        },
        {
            "uid": "bce18827c769a47c13fce74785fe393bf3c6d929",
            "year": 2011,
            "grantee_name": "COMMUNITY RENEWAL TEAM OF GREATER HARTFORD",
            "grant_number": "01CH0116",
            "program_address_line_1": "555 Windsor Street",
            "program_address_line_2": None,
            "program_agency_description": "Grantee that directly operates programs and delegates service delivery",
            "program_agency_type": "Community Action Agency (CAA)",
            "program_city": "Hartford",
            "program_email": "rodriguezl@crtct.org",
            "program_name": "Community Renewal Team, Inc. (CRT)",
            "program_number": "000",
            "program_phone": "(860) 560-5608",
            "program_type": "HS",
            "program_state": "CT",
            "program_zip1": "06120",
            "program_zip2": "2418",
            "region": 1,
        },
        {
            "uid": "7d5581c2713050b2b48e99014bf6f7d4743416f3",
            "year": 2011,
            "grantee_name": "COMMUNITY RENEWAL TEAM OF GREATER HARTFORD",
            "grant_number": "01CH0116",
            "program_address_line_1": "95 Willowbrook Road",
            "program_address_line_2": None,
            "program_agency_description": "Delegate agency",
            "program_agency_type": "School System",
            "program_city": "East Hartford",
            "program_email": "lebeau.j@easthartford.org",
            "program_name": "Willowbrook School - Early Childhood Center",
            "program_number": "003",
            "program_phone": "(860) 622-5520",
            "program_type": "HS",
            "program_state": "CT",
            "program_zip1": "06118",
            "program_zip2": "1842",
            "region": 1,
        },
        {
            "uid": "1744959b69d05cea9ed7fb54020a8978d1561dbc",
            "year": 2011,
            "grantee_name": "COMMUNITY RENEWAL TEAM OF GREATER HARTFORD",
            "grant_number": "01CH0116",
            "program_address_line_1": "55 South Street",
            "program_address_line_2": "254 Lake Ave",
            "program_agency_description": "Delegate agency",
            "program_agency_type": "Community Action Agency (CAA)",
            "program_city": "Bristol",
            "program_email": "vpelletier@bcoct.org",
            "program_name": "BCO Bristol Head Start",
            "program_number": "006",
            "program_phone": "(860) 584-9307 x15",
            "program_type": "HS",
            "program_state": "CT",
            "program_zip1": "06010",
            "program_zip2": "6524",
            "region": 1,
        },
        {
            "uid": "046cb2f15b888f03467224fe0a7cbec0cbf8f487",
            "year": 2011,
            "grantee_name": "EDUCATION CONNECTION",
            "grant_number": "01CH0117",
            "program_address_line_1": "355 Goshen Road",
            "program_address_line_2": None,
            "program_agency_description": "Grantee that directly operates program(s) and has no delegates",
            "program_agency_type": "Community Action Agency (CAA)",
            "program_city": "Litchfield",
            "program_email": "bleacher@educationconnection.org",
            "program_name": "Education Connection",
            "program_number": "000",
            "program_phone": "(860) 567-0863",
            "program_type": "HS",
            "program_state": "CT",
            "program_zip1": "06759",
            "program_zip2": None,
            "region": 1,
        },
        {
            "uid": "0f10477d8ea7a32365431004172f735bd5874b42",
            "year": 2011,
            "grantee_name": "EDUCATION CONNECTION",
            "grant_number": "01CH0117",
            "program_address_line_1": "355 Goshen Road",
            "program_address_line_2": "P.O. Box 909",
            "program_agency_description": "Grantee that directly operates program(s) and has no delegates",
            "program_agency_type": "Community Action Agency (CAA)",
            "program_city": "Litchfield",
            "program_email": "info@educationconnection.org",
            "program_name": "Education Connection",
            "program_number": "200",
            "program_phone": "(860) 567-0863",
            "program_type": "EHS",
            "program_state": "CT",
            "program_zip1": "06759",
            "program_zip2": "0909",
            "region": 1,
        },
        {
            "uid": "f3d6a04c8f8b4c72a88f526f743d01cb320279b9",
            "year": 2011,
            "grantee_name": "NEW OPPORTUNITIES FOR WATERBURY, INC",
            "grant_number": "01CH0157",
            "program_address_line_1": "232 North Elm Street",
            "program_address_line_2": None,
            "program_agency_description": "Grantee that directly operates programs and delegates service delivery",
            "program_agency_type": "Community Action Agency (CAA)",
            "program_city": "Waterbury",
            "program_email": "thirst@newopportunities.org",
            "program_name": "New Opportunities, Inc.",
            "program_number": "000",
            "program_phone": "(203) 759-0841",
            "program_type": "HS",
            "program_state": "CT",
            "program_zip1": "06702",
            "program_zip2": "1516",
            "region": 1,
        },
        {
            "uid": "5c7e255a576f38368e980f8a3daed95e872dc8fc",
            "year": 2011,
            "grantee_name": "NEW OPPORTUNITIES FOR WATERBURY, INC",
            "grant_number": "01CH0157",
            "program_address_line_1": "100 Prospect St.",
            "program_address_line_2": None,
            "program_agency_description": "Delegate agency",
            "program_agency_type": "School System",
            "program_city": "Naugatuck",
            "program_email": "naugheadstart@yahoo.com",
            "program_name": "Naugatuck Head Start",
            "program_number": "001",
            "program_phone": "(203) 720-5239",
            "program_type": "HS",
            "program_state": "CT",
            "program_zip1": "06770",
            "program_zip2": "4211",
            "region": 1,
        },
        {
            "uid": "daa8bd5072a7016b361fe6213dda6a8553366a38",
            "year": 2011,
            "grantee_name": "NEW OPPORTUNITIES FOR WATERBURY, INC",
            "grant_number": "01CH0157",
            "program_address_line_1": "232 North Elm Street",
            "program_address_line_2": None,
            "program_agency_description": "Grantee that directly operates program(s) and has no delegates",
            "program_agency_type": "Community Action Agency (CAA)",
            "program_city": "Waterbury",
            "program_email": "thirst@newopportunitiesinc.org",
            "program_name": "New Opportunities, Inc.",
            "program_number": "200",
            "program_phone": "(203) 759-0841",
            "program_type": "EHS",
            "program_state": "CT",
            "program_zip1": "06702",
            "program_zip2": "1516",
            "region": 1,
        },
    ]


@pytest.fixture(scope="module")
def response_records():
    return [
        # {
        #     "uid": "c27e16e43f9feaea33441d1857989a64cd439a52",
        #     "question_id": "b5c2dd4e8fe4523405cfcd2753da583d669db2af",
        #     "year": 2011,
        #     "answer": None,
        # },
        # {
        #     "uid": "c27e16e43f9feaea33441d1857989a64cd439a52",
        #     "question_id": "8927c779743d6ace9cccf4f8c9cf1b68f6fc1a6b",
        #     "year": 2012,
        #     "answer": None,
        # },
        {
            "uid": "c27e16e43f9feaea33441d1857989a64cd439a52",
            "question_id": "b5c2dd4e8fe4523405cfcd2753da583d669db2af",
            "year": 2011,
            "answer": None,
        },
    ]


@pytest.fixture(scope="module")
def insert_program_records(sql_utils, program_records):
    sql_utils.insert_records(program_records, "program")


@pytest.fixture(scope="module")
def insert_response_records(sql_utils, response_records):
    sql_utils.insert_records(response_records, "response")
