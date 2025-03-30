import pytest

from pir_pipeline.utils.MockData import MockData


@pytest.fixture
def insertable(request, mock_data):
    insertable = mock_data().generate_data().export(how="Insertable")

    validation = {}
    for workbook in insertable._data.values():
        for table, data in workbook.items():
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
            if validation.get(table):
                validation[table] += data.shape[0]
            else:
                validation[table] = data.shape[0]

            records = data.to_dict(orient="records")
            sql_utils.insert_records(records, table)

    request.cls.validation = validation
