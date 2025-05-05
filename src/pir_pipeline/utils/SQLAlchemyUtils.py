"""Utilities for interacting with SQL via SQLAlchemy"""

import os
from subprocess import run as srun
from typing import Self

import pandas as pd
from sqlalchemy import URL, Engine, Select, Table, create_engine, text, update
from sqlalchemy.sql.elements import BinaryExpression, BooleanClauseList
from sqlalchemy_utils import create_database, database_exists, drop_database

from pir_pipeline.config import DB_CONFIG
from pir_pipeline.models.pir_sql_models import (
    confirmed,
    linked,
    program,
    question,
    response,
    sql_metadata,
    unconfirmed,
    unlinked,
    uqid_changelog,
)
from pir_pipeline.utils.SQLUtils import SQLUtils
from pir_pipeline.utils.utils import get_searchable_columns


class SQLAlchemyUtils(SQLUtils):
    def __init__(self, user: str, password: str, host: str, port: int, database: str):
        try:
            srun(["psql", "--version"])
            drivername = "postgresql+psycopg"
        except Exception:
            if os.environ.get("IN_AWS_LAMBDA"):
                drivername = "postgresql+psycopg"
            else:
                drivername = "mysql+mysqlconnector"

        self._engine: Engine
        self.gen_engine(
            username=user,
            password=password,
            host=host,
            port=port,
            database=database,
            drivername=drivername,
        )

        if self._engine.name == "mysql":
            from sqlalchemy.dialects.mysql import insert
        elif self._engine.name == "postgresql":
            from sqlalchemy.dialects.postgresql import insert

        self.insert = insert
        self._dialect = self._engine.name
        self._tables: dict[Table] = {
            "response": response,
            "question": question,
            "program": program,
            "linked": linked,
            "unlinked": unlinked,
            "uqid_changelog": uqid_changelog,
            "confirmed": confirmed,
            "unconfirmed": unconfirmed,
        }
        self._database = database

    @property
    def engine(self):
        """Return the database engine"""

        return self._engine

    @property
    def tables(self):
        """Return the tables in the database"""

        return self._tables

    @property
    def database(self):
        """Return the database name"""

        return self._database

    def make_connection(self):
        pass

    def close_connection(self):
        pass

    def gen_engine(self, **kwargs) -> Self:
        """Generate database engine

        Returns:
            Self: Object of class SQLAlchemyUtils
        """

        engine_url = URL.create(**kwargs)
        self._engine = create_engine(engine_url)
        return self

    def create_db(self) -> Self:
        """Create the target database

        Returns:
            Self: Object of class SQLAlchemyUtils
        """

        if not database_exists(self._engine.url):
            create_database(self._engine.url)
            assert database_exists(self._engine.url)

        sql_metadata.create_all(self._engine)

        return self

    def drop_db(self) -> Self:
        """Drop the target database

        Returns:
            Self: Object of class SQLAlchemyUtils
        """

        if database_exists(self._engine.url):
            drop_database(self._engine.url)

    def validate_table(self, table: str):
        """Assert that the table provided is among the list of valid tables.

        Args:
            table (str): Table name
        """

        valid_tables = list(self._tables.keys())
        assert table in valid_tables, "Invalid table."

    def get_columns(self, table: str, where: str = "") -> list[str]:
        """Get column names from the specified table

        Args:
            table (str): Table name
            where (str): Additional where condition by which to filter columns returned.

        Returns:
            list[str]: A list of column names
        """

        if not where:
            self.validate_table(table)
            columns = self._tables[table].c.keys()
        else:
            if self._dialect == "mysql":
                table_schema = "table_schema"
            elif self._dialect == "postgresql":
                table_schema = "table_catalog"

            query = text(
                f"""
                SELECT column_name 
                FROM information_schema.columns 
                WHERE table_name = :table AND {table_schema} = :schema {where}
                """
            )
            with self._engine.connect() as conn:
                result = conn.execute(
                    query, {"table": table, "schema": self._database, "where": where}
                )
                columns = [res[0] for res in result.all()]

        return columns

    def get_records(
        self, query: str | Select, records: dict | list[dict] = None
    ) -> pd.DataFrame:
        """Return records from the database

        Args:
            query (str | Select): A query to execute
            records (dict | list[dict], optional): Records to use for bound parameters. Defaults to None.

        Returns:
            pd.DataFrame: Records returned by the query
        """

        if isinstance(query, str):
            df = pd.read_sql(query, self._engine)
        elif isinstance(query, Select):
            with self._engine.connect() as conn:
                if records:
                    result = conn.execute(query, records)
                else:
                    result = conn.execute(query)
                records = result.all()

            records = self.to_dict(records, query.selected_columns.keys())
            df = pd.DataFrame.from_records(records)

        return df

    def insert_records(self, records: list[dict], table: str):
        """Insert records into the target table

        Args:
            records (list[dict]): A list of records for insertion
            table (str): Table name
        """

        def insert_query(records: list[dict]):
            """Create an insertion query

            Args:
                records (list[dict]): A list of records for insertion
            """

            with self._engine.begin() as conn:
                insert_statement = self.insert(self._tables[table])

                if self._dialect == "mysql":
                    values = insert_statement.inserted
                elif self._dialect == "postgresql":
                    values = insert_statement.excluded

                column_dict = {
                    column.name: column
                    for column in values
                    if column.name in upsert_columns
                }
                if self._dialect == "mysql":
                    upsert_statement = insert_statement.on_duplicate_key_update(
                        column_dict
                    )
                elif self._dialect == "postgresql":
                    index_elements = set(insert_statement.table.c.keys()) - set(
                        upsert_columns
                    )
                    index_elements = list(index_elements)
                    upsert_statement = insert_statement.on_conflict_do_update(
                        constraint=f"pk_{table}",
                        set_=column_dict,
                    )

                conn.execute(upsert_statement, records)

        # Remove primary key columns for upserting
        upsert_columns = get_searchable_columns(self.get_columns(table))
        upsert_columns = [column.lower() for column in upsert_columns]

        # If there are more than 20000 records, ingest in batches
        batch_size = 80000
        if len(records) > batch_size:
            num_records = len(records)
            # Logic sourced from Microsoft Copilot
            batches = [
                records[i : i + batch_size] for i in range(0, num_records, batch_size)
            ]

            for batch in batches:
                insert_query(batch)
        else:
            insert_query(records)

    def update_records(
        self,
        table: Table,
        set: dict[str],
        where: BinaryExpression | BooleanClauseList,
        records: list[dict] = [],
    ):
        """Update records in the database

        Args:
            table (Table): Table name
            set (dict[str]): Dictionary indicating how to update values.
            where (BinaryExpression | BooleanClauseList): Clause indicating which values to update.
            records (list[dict], optional): List of records to use in update. Defaults to [].
        """

        statement = update(table).where(where).values(**set)

        with self._engine.begin() as conn:
            if records:
                conn.execute(statement, records)
            else:
                conn.execute(statement)

    def to_dict(self, records: list[tuple], columns: list[str]) -> list[dict]:
        """Convert a list of tuples to a list of dictionaries

        Args:
            records (list[tuple]): Records, i.e. values in the resultant dictionaries.
            columns (list[str]): Columns, i.e. keys in the resultant dictionaries.

        Returns:
            list[dict]: List of dictionaries.
        """

        data = []
        for record in records:
            assert len(record) == len(columns)
            result_dict = {key: record[i] for i, key in enumerate(columns)}
            data.append(result_dict)

        return data

    def get_scalar(self, query: str | Select, records: dict):
        """Return a scalar from a query

        Args:
            query (str|Select): A query to execute
            records (dict): A dictionary containing parameters to match
        """

        with self.engine.connect() as conn:
            result = conn.execute(query, records)
            return result.scalar()


if __name__ == "__main__":
    SQLAlchemyUtils(
        **DB_CONFIG, database="pir", drivername="mysql+mysqlconnector"
    ).create_db()
