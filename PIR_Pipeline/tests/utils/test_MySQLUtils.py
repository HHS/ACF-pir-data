import os

import pandas as pd
import pytest
from dotenv import load_dotenv

from pir_pipeline.utils.MySQLUtils import MySQLUtils

load_dotenv()


@pytest.fixture(scope="class")
def mysql_utils(request):
    request.cls._sql = MySQLUtils(
        user=os.getenv("dbusername"),
        password=os.getenv("dbpassword"),
        host=os.getenv("dbhost"),
        port=os.getenv("dbport"),
    )


@pytest.mark.usefixtures("mysql_utils")
class TestMySQLUtils:
    def test_make_close_db_connections(self):
        self._sql.make_db_connections(["pir_question_links"])
        assert self._sql._connections["pir_question_links"].is_connected()
        self._sql.close_db_connections()
        assert not self._sql._connections["pir_question_links"].is_connected()

    def test_get_schemas(self):
        schemas = (
            self._sql.make_db_connections(["pir_question_links"])
            .get_schemas("pir_question_links", ["linked", "unlinked"])
            ._schemas
        )
        assert len(schemas) == 2
        assert all([isinstance(schema, pd.DataFrame) for schema in schemas.values()])

    def test_get_records(self):
        connection = "pir_question_links"
        df = self._sql.make_db_connections([connection]).get_records(
            connection, "SELECT * FROM linked limit 10"
        )
        assert isinstance(df, pd.DataFrame)
        assert df.shape == (10, 8)

    def test_get_columns(self):
        connection = "pir_question_links"
        columns = self._sql.make_db_connections([connection]).get_columns(
            connection, "linked", "AND column_name LIKE '%question%'"
        )
        columns.sort()
        assert columns == [
            "question_id",
            "question_name",
            "question_number",
            "question_text",
        ], f"Incorrect columns: {columns}"


if __name__ == "__main__":
    pytest.main([__file__, "-s"])
