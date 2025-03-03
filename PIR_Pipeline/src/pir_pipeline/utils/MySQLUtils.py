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

    def insert_records(self, columns: tuple[str], records: list[dict], table: str):
        def insertion_query(columns, records, table):
            query = f"""REPLACE INTO %s ({', '.join(columns)}) VALUES """ % (table)
            escape_string = ", ".join(["%s"] * len(columns))
            escape_string = f"({escape_string})"
            escape_string = ", ".join([escape_string] * len(records))
            query += escape_string

            to_insert = []
            for record in records:
                for value in record.values():
                    to_insert.append(value)

            to_insert = tuple(to_insert)

            cursor = self._connection.cursor(buffered=True, write_timeout=0)
            cursor.execute(query, to_insert)
            self._connection.commit()
            cursor.close()

        if len(records) < 20000:
            insertion_query(columns, records, table)
        else:
            num_records = len(records)
            upper_bound = 20000
            lower_bound = 0
            batches = []
            while upper_bound < num_records:
                if lower_bound == 0:
                    pass
                else:
                    lower_bound += 20000
                    upper_bound += 20000

                batches.append(records[lower_bound:upper_bound])

            for batch in batches:
                insertion_query(columns, batch, table)

    def update_records(self, table, set: dict[str], where: str):
        query = "UPDATE %s" % (table)
        set = ", ".join([f"{key} = '{value}'" for key, value in set.items()])
        query = query + " SET " + set
        query += " WHERE %s" % (where)

        cursor = self._connection.cursor(buffered=True)
        cursor.execute(query)

        try:
            assert cursor.rowcount == 1, "More than one row affected"
        except AssertionError:
            self._connection.rollback()
            raise

        self._connection.commit()
        cursor.close()
