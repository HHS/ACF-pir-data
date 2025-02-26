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

    def close_db_connections(self):
        return super().close_db_connections()

    def get_header(self, cursor):
        description = cursor.description
        header = [row[0] for row in description]

        return header

    def get_schemas(self, connection: str, tables: list[str]) -> Self:
        cursor = self._connections[connection].cursor(buffered=True)
        schemas = {}
        for table in tables:
            query = "SHOW COLUMNS FROM %s" % (table)
            cursor.execute(query)
            header = self.get_header(cursor)
            values = cursor.fetchall()
            schemas[table] = pd.DataFrame.from_records(values, columns=header)

        self._schemas = schemas
        cursor.close()
        return self

    def get_records(self, connection, query) -> pd.DataFrame:
        cursor = self._connections[connection].cursor(buffered=True)
        cursor.execute(query)
        records = cursor.fetchall()
        header = self.get_header(cursor)
        df = pd.DataFrame.from_records(records, columns=header)
        cursor.close()

        return df

    def get_columns(self, connection: str, table: str, query: str = None):
        cursor = self._connections[connection].cursor(buffered=True)
        base_query = """
            SELECT column_name
            FROM information_schema.columns
            WHERE table_name = '%s'
        """ % (
            table
        )
        if query:
            base_query += query

        cursor.execute(base_query)
        columns = cursor.fetchall()
        columns = [column[0] for column in columns]
        return columns
