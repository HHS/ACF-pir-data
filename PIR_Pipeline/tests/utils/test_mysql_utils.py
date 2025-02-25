import os

import mysql.connector
import pytest
from dotenv import load_dotenv

from pir_pipeline.utils import mysql_utils

load_dotenv()


class TestGetSchemas:
    def test_get_schemas(self):
        connection = mysql.connector.connect(
            user=os.getenv("dbusername"),
            password=os.getenv("dbpassword"),
            host=os.getenv("dbhost"),
            port=os.getenv("dbport"),
            database="pir_question_links",
        )
        schemas = mysql_utils.get_schemas(connection, ["linked", "unlinked"])
        assert len(schemas) == 2


if __name__ == "__main__":
    pytest.main([__file__, "-s"])
