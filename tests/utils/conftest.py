import numpy as np
import pytest

from pir_pipeline.utils.MockData import MockData
from pir_pipeline.dashboard import create_app


@pytest.fixture
def app():
    app = create_app()
    app.config.update(
        {
            "TESTING": True,
        }
    )

    yield app


@pytest.fixture
def client(app):
    return app.test_client()


@pytest.fixture
def runner(app):
    return app.test_cli_runner()


@pytest.fixture
def insertable(request, mock_data):
    insertable = mock_data().generate_data().export(how="Insertable")

    validation = {}
    for workbook in insertable._data.values():
        for table, data in workbook.items():
            data.replace({np.nan: None}, inplace=True)
            if validation.get(table):
                validation[table] += data.shape[0]
            else:
                validation[table] = data.shape[0]

    request.cls.validation = validation

    return insertable


@pytest.fixture(scope="class")
def inserted(request, sql_utils):
    mock_data = MockData().generate_data().export(how="Insertable")

    validation = {}
    for workbook in mock_data._data.values():
        for table, data in workbook.items():
            data.replace({np.nan: None}, inplace=True)
            if validation.get(table):
                validation[table] += data.shape[0]
            else:
                validation[table] = data.shape[0]

            records = data.to_dict(orient="records")
            sql_utils.insert_records(records, table)

    request.cls.validation = validation


@pytest.fixture(scope="class")
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
