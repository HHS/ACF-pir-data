from urllib.parse import quote_plus

import pandas as pd
from sqlalchemy import Engine, Table, create_engine, update
from sqlalchemy.sql.elements import BinaryExpression, BooleanClauseList

from pir_pipeline.config import db_config
from pir_pipeline.models.pir_models_sql_alchemy import (
    linked,
    program,
    question,
    response,
    unlinked,
)
from pir_pipeline.utils.SQLUtils import SQLUtils
from pir_pipeline.utils.utils import get_searchable_columns


class SQLAlchemyUtils(SQLUtils):
    def __init__(self, user: str, password: str, host: str, port: int, database: str):
        self._engine: Engine = create_engine(
            f"mysql+mysqlconnector://{user}:{quote_plus(password)}@{host}:{port}/{database}"
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

    @property
    def engine(self):
        return self._engine

    @property
    def tables(self):
        return self._tables

    def make_connection(self):
        pass

    def close_connection(self):
        pass

    def get_schemas(self, tables: list[str]) -> dict[list | tuple]:
        valid_tables = (
            "response",
            "question",
            "program",
        )
        schemas = {}
        for table in tables:
            assert table in valid_tables, "Invalid table."
            query = f"SHOW COLUMNS FROM {table}"
            schemas[table] = pd.read_sql(query, self._engine)

        self._schemas = schemas
        return self

    def get_columns(self, table: str) -> list[str]:
        return self._tables[table].c.keys()

    def get_records(self, query: str) -> pd.DataFrame:
        return pd.read_sql(query, self._engine)

    def insert_records(self, records: list[dict], table: str):
        upsert_columns = get_searchable_columns(self.get_columns(table))
        upsert_columns = [column.lower() for column in upsert_columns]
        with self._engine.begin() as conn:
            insert_statement = self.insert(self._tables[table])
            column_dict = {
                column.name: column
                for column in insert_statement.inserted
                if column.name in upsert_columns
            }
            if self._dialect == "mysql":
                upsert_statement = insert_statement.on_duplicate_key_update(column_dict)
            elif self._dialect == "postgresql":
                upsert_statement = insert_statement.on_conflict_do_update(column_dict)

            conn.execute(upsert_statement, records)

    def update_records(
        self,
        table: str,
        set: dict[str],
        where: BinaryExpression | BooleanClauseList,
        records: list[dict] = [],
    ):

        statement = update(self._tables[table]).where(where).values(**set)

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


if __name__ == "__main__":
    print(SQLAlchemyUtils(**db_config, database="pir").get_columns("response"))
