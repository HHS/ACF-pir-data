from typing import Self

import mysql.connector
import pandas as pd

from pir_pipeline.utils.SQLUtils import SQLUtils


class MySQLUtils(SQLUtils):
    def __init__(self, user: str, password: str, host: str, port: int):
        super().__init__(user, password, host, port)

    def make_connection(self, database: str) -> Self:
        self._connection = mysql.connector.connect(**self._db_config, database=database)

        return self

    def close_connection(self):
        return super().close_connection()

    def get_header(self, cursor):
        description = cursor.description
        header = [row[0] for row in description]

        return header

    def get_schemas(self, tables: list[str]) -> Self:
        cursor = self._connection.cursor(buffered=True)
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

    def get_records(self, query) -> pd.DataFrame:
        cursor = self._connection.cursor(buffered=True)
        cursor.execute(query)
        records = cursor.fetchall()
        header = self.get_header(cursor)
        df = pd.DataFrame.from_records(records, columns=header)
        cursor.close()

        return df

    def get_columns(self, table: str, query: str = None):
        cursor = self._connection.cursor(buffered=True)
        base_query = """
            SELECT column_name
            FROM information_schema.columns
            WHERE table_name = '%s' AND table_schema = '%s'
        """ % (
            table,
            self._connection.database,
        )
        if query:
            base_query += query

        cursor.execute(base_query)
        columns = cursor.fetchall()
        cursor.close()

        columns = [column[0] for column in columns]
        return columns

    def insert_records(self, df: pd.DataFrame, table: str):
        columns = tuple(df.columns.tolist())
        query = """REPLACE INTO %s %s VALUES""" % (table, columns)
        query += " (%s)"
        records = df.to_records()

        exit()
        cursor = self._connection.cursor(buffered=True)
        cursor.executemany(query, records)
        cursor.close()
