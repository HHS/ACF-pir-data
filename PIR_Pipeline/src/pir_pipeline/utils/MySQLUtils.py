"""A class containing utilities for interfacing with MySQL databases"""

from typing import Self

import mysql.connector
import pandas as pd
from mysql.connector.cursor import MySQLCursor

from pir_pipeline.utils.SQLUtils import SQLUtils


class MySQLUtils(SQLUtils):
    """A class containing utilities for interfacing with MySQL databases"""

    def __init__(self, user: str, password: str, host: str, port: int):
        """Instantiate a MySQLUtils object

        Args:
            user (str): Database username
            password (str): Database password
            host (str): Database host
            port (int): Database port
        """
        super().__init__(user, password, host, port)

    def make_connection(self, database: str) -> Self:
        """Make a connection to the target database

        Args:
            database (str): The name of a database to connect to

        Returns:
            Self: MySQLUtils object
        """
        self._connection = mysql.connector.connect(**self._db_config, database=database)

        return self

    def close_connection(self):
        """Close the database connection"""
        self._connection.close()

        return self

    def get_header(self, cursor: MySQLCursor) -> list[str]:
        """Get the header row/column names from a query

        Args:
            cursor (MySQLCursor): MySQL cursor

        Returns:
            list[str]: A list containing the column names
        """
        description = cursor.description
        header = [row[0] for row in description]

        return header

    def get_schemas(self, tables: list[str]) -> Self:
        """Get table schemas

        Args:
            tables (list[str]): A list of tables for which to get schemas

        Returns:
            Self: MySQLUtils object
        """
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

    def get_records(self, query: str) -> pd.DataFrame:
        """Get the records returned by the provided query

        Args:
            query (str): A SQL query

        Returns:
            pd.DataFrame: Records returned by the SQL query as a pandas data frame
        """
        cursor = self._connection.cursor(buffered=True)
        cursor.execute(query)
        records = cursor.fetchall()
        header = self.get_header(cursor)
        df = pd.DataFrame.from_records(records, columns=header)
        cursor.close()

        return df

    def get_columns(self, table: str, query: str = None) -> list[str]:
        """Return column names from the target table

        Args:
            table (str): The table to get column names from
            query (str): Additional statements to add to the WHERE clause

        Returns:
            list[str]: Column names
        """
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

    def insert_records(self, records: list[dict], table: str):
        """Insert records in the target table

        If there are less than 20000 records, they will be inserted using a single
        statement. Otherwise, batches of 20000 records at a time will be inserted.

        Args:
            records (list[dict]): Records to insert
            table (str): Table to insert records into
        """

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

        columns = list(records[0].keys())
        batch_size = 20000
        if len(records) < batch_size:
            insertion_query(columns, records, table)
        else:
            num_records = len(records)
            # Logic sourced from Microsoft Copilot
            batches = [
                records[i : i + batch_size] for i in range(0, num_records, batch_size)
            ]

            for batch in batches:
                insertion_query(columns, batch, table)

    def update_records(self, table, set: dict[str], where: str):
        """Update a record/records in the target table

        Args:
            table (_type_): The table containing the record(s) to update
            set (dict[str]): A dictionary defining the key, value pairs to be updated.
            where (str): SQL syntax defining a where condition to limit the records being updated.
        """
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
