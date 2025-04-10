import numpy as np
import pytest

from pir_pipeline.utils.MockData import MockData


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
        {
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
        {
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
        {
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
