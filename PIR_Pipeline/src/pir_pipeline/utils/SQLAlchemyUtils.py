from typing import Self

import pandas as pd
from sqlalchemy import URL, Engine, Table, create_engine, text, update
from sqlalchemy.sql.elements import BinaryExpression, BooleanClauseList
from sqlalchemy_utils import create_database, database_exists, drop_database

from pir_pipeline.config import db_config
from pir_pipeline.models.pir_sql_models import (
    linked,
    program,
    question,
    response,
    sql_metadata,
    unlinked,
)
from pir_pipeline.utils.SQLUtils import SQLUtils
from pir_pipeline.utils.utils import get_searchable_columns


class SQLAlchemyUtils(SQLUtils):
    def __init__(
        self,
        user: str,
        password: str,
        host: str,
        port: int,
        database: str,
        drivername: str = "mysql+mysqlconnector",
    ):
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
        }
        self._database = database

    @property
    def engine(self):
        return self._engine

    @property
    def tables(self):
        return self._tables

    @property
    def database(self):
        return self._database

    def make_connection(self):
        pass

    def close_connection(self):
        pass

    def gen_engine(self, **kwargs) -> Self:
        engine_url = URL.create(**kwargs)
        self._engine = create_engine(engine_url)
        return self

    def create_db(self):
        if not database_exists(self._engine.url):
            create_database(self._engine.url)
            assert database_exists(self._engine.url)

        sql_metadata.create_all(self._engine)

        return self

    def drop_db(self):
        if database_exists(self._engine.url):
            drop_database(self._engine.url)

    def validate_table(self, table: str):
        valid_tables = list(self._tables.keys())
        assert table in valid_tables, "Invalid table."

    def get_columns(self, table: str, where: str = "") -> list[str]:
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

    def get_records(self, query: str) -> pd.DataFrame:
        return pd.read_sql(query, self._engine)

    def insert_records(self, records: list[dict], table: str):
        def insert_query(records: list[dict]):
            with self._engine.begin() as conn:
                insert_statement = self.insert(self._tables[table])
                column_dict = {
                    column.name: column
                    for column in insert_statement.inserted
                    if column.name in upsert_columns
                }
                if self._dialect == "mysql":
                    upsert_statement = insert_statement.on_duplicate_key_update(
                        column_dict
                    )
                elif self._dialect == "postgresql":
                    upsert_statement = insert_statement.on_conflict_do_update(
                        column_dict
                    )

                conn.execute(upsert_statement, records)

        upsert_columns = get_searchable_columns(self.get_columns(table))
        upsert_columns = [column.lower() for column in upsert_columns]

        batch_size = 20000
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

        statement = update(table).where(where).values(**set)

        with self._engine.begin() as conn:
            if records:
                conn.execute(statement, records)
            else:
                conn.execute(statement)

    def to_dict(self, records: list[tuple], columns: list[str]) -> list[dict]:
        data = []
        for record in records:
            assert len(record) == len(columns)
            result_dict = {key: record[i] for i, key in enumerate(columns)}
            data.append(result_dict)

        return data

    def insert_from_file(self, file: str, table: str):
        self.validate_table(table)
        if self._dialect == "mysql":
            query = text(
                f"""
                LOAD DATA 
                INFILE :file 
                REPLACE INTO TABLE {table}
                CHARACTER SET utf8
                FIELDS TERMINATED BY ','
                ENCLOSED BY '"'
                ESCAPED BY '"'
                LINES TERMINATED BY '\r\n'
                """
            )
        elif self._dialect == "postgresql":
            pass

        with self._engine.connect() as conn:
            conn.execute(query, {"file": file})


if __name__ == "__main__":
    SQLAlchemyUtils(
        **db_config, database="pir", drivername="postgresql+psycopg"
    ).get_columns("response")
