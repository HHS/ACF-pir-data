import pytest


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
