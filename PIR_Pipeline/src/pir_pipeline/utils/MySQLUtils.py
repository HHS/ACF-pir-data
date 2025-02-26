from typing import Self

import mysql.connector
import pandas as pd

from pir_pipeline.utils.SQLUtils import SQLUtils


class MySQLUtils(SQLUtils):
    def __init__(self, user: str, password: str, host: str, port: int):
        super().__init__(user, password, host, port)

    def make_db_connections(self, databases: list[str]) -> Self:
        connections = {}
        for database in databases:
            connection = mysql.connector.connect(**self._db_config, database=database)
            connections[database] = connection

        self._connections = connections
        return self

    def get_schemas(self, connection: str, tables: list[str]) -> Self:
        cursor = self._connections[connection].cursor(buffered=True)
        schemas = {}
        for table in tables:
            query = "SHOW COLUMNS FROM %s" % (table)
            cursor.execute(query)
            description = cursor.description
            header = [row[0] for row in description]
            values = cursor.fetchall()
            values.insert(0, header)
            schemas[table] = values

        for schema, array in schemas.items():
            schemas[schema] = pd.DataFrame.from_records(array[1:], columns=array[0])

        self._schemas = schemas
        return self

    def close_db_connections(self):
        return super().close_db_connections()
