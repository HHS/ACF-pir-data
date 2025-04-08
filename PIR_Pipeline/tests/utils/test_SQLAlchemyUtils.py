import numpy as np
import pytest
from sqlalchemy import bindparam, select, text

from pir_pipeline.config import db_config
from pir_pipeline.utils.SQLAlchemyUtils import SQLAlchemyUtils


def test_create_db(sql_utils, request):
    sql_utils.create_db()
    if request.module.drivername == "mysql+mysqlconnector":
        query = text(
            "SELECT table_schema FROM information_schema.tables WHERE table_schema = 'pir_test'"
        )
    else:
        query = text("SELECT 1 FROM pg_database WHERE datname = 'pir_test'")
    with sql_utils.engine.connect() as conn:
        result = conn.execute(query)
        exists = result.first()[0]

    assert exists, "pir_test database does not exist"


def test_drop_db(sql_utils, request):
    sql_utils.drop_db()
    sql_utils.engine.dispose()
    if request.module.drivername == "mysql+mysqlconnector":
        database = "mysql"
        query = text(
            "SELECT table_schema FROM information_schema.tables WHERE table_schema = 'pir_test'"
        )
    else:
        database = "postgres"
        query = text("SELECT 1 FROM pg_database WHERE datname = 'pir_test'")
    sql = SQLAlchemyUtils(**db_config, database=database)
    with sql.engine.connect() as conn:
        result = conn.execute(query)
        exists = result.first()

    assert not exists, "pir_test database still exists"
    sql.engine.dispose()


@pytest.mark.usefixtures("create_database")
class TestSQLAlchemyUtilsNoData:
    def test_gen_engine(self, request):
        db_config.update({"username": db_config["user"]})
        db_config.pop("user")
        query = select(text("'Connection Made'"))
        with SQLAlchemyUtils.__new__(SQLAlchemyUtils).gen_engine(
            **db_config, database="pir_test", drivername=request.module.drivername
        )._engine.connect() as conn:
            result = conn.execute(query)
            value = result.first()

        assert value[0] == "Connection Made", "Incorrect value."

    def test_validate_table(self, sql_utils):
        for table in ["invalid1", "drop table response", "invalid_2"]:
            with pytest.raises(AssertionError):
                sql_utils.validate_table(table)

    def test_get_columns(
        self, sql_utils, question_columns, response_columns, program_columns
    ):
        # Get all columns from a table
        correct = {
            "program": program_columns,
            "question": question_columns,
            "response": response_columns,
        }
        for table in ["program", "question", "response"]:
            columns = sql_utils.get_columns(table)
            assert (
                set(columns) == correct[table]
            ), f"Columns are incorrect for table: {table}"
            assert isinstance(columns, list), "Columns are not in a list"

        # Get a subset
        columns = sql_utils.get_columns("program", "AND column_name LIKE '%zip%'")
        assert set(columns) == {"program_zip1", "program_zip2"}
        assert isinstance(columns, list), "Columns are not in a list"

    def test_insert_records(self, insertable, sql_utils):
        for workbook in insertable._data.values():
            for table, data in workbook.items():
                records = data.to_dict(orient="records")
                sql_utils.insert_records(records, table)

        for table in self.validation:
            with sql_utils._engine.connect() as conn:
                result = conn.execute(text(f"SELECT COUNT(*) FROM {table}"))
                record_count = result.first()[0]

            assert record_count == self.validation[table]


@pytest.mark.usefixtures("inserted", "create_database")
class TestSQLAlchemyUtilsData:
    def test_get_records(self, db_columns, sql_utils):
        queries = [
            (
                "SELECT * FROM response",
                self.validation["response"],
                db_columns["response"],
            ),
            (
                "SELECT * FROM question WHERE section = 'A'",
                (self.validation["question"] / 4) - 1,
                db_columns["question"],
            ),
            (
                "SELECT * FROM unlinked",
                self.validation["question"],
                db_columns["question"],
            ),
        ]
        for query in queries:
            frame = sql_utils.get_records(query[0])
            assert frame.shape[0] == query[1]
            assert set(frame.columns) == query[2]

    def test_update_records(self, sql_utils):
        table = sql_utils.tables["question"]
        sql_utils.update_records(table, {"uqid": "1"}, True)
        uqids = sql_utils.get_records("question")["uqid"].tolist()
        assert set(uqids) == {"1"}, f"Incorrect uqids: {set(uqids)}"

        section_a = sql_utils.get_records("SELECT * FROM question WHERE section = 'A'")
        section_a.replace({np.nan: None}, inplace=True)
        section_a.rename(columns={"question_id": "qid"}, inplace=True)
        section_a["uqid"] = "A"
        records = section_a.to_dict(orient="records")
        sql_utils.update_records(
            table,
            {"uqid": bindparam("uqid")},
            table.c["question_id"] == bindparam("qid"),
            records,
        )
        uqids = sql_utils.get_records("question")["uqid"].tolist()
        assert set(uqids) == {"1", "A"}, f"Incorrect uqids: {set(uqids)}"
        assert len(
            [uqid for uqid in uqids if uqid == "A"]
        ), "Incorrect number of 'A' uqids"

    def test_to_dict(self, sql_utils):
        with sql_utils._engine.connect() as conn:
            result = conn.execute(text("SELECT * FROM response"))
            columns = list(result.keys())
            records = result.all()

        expected_rows = len(records)
        record_dict = sql_utils.to_dict(records, columns)
        assert set(record_dict[0].keys()) == {
            "uid",
            "question_id",
            "year",
            "answer",
        }, f"Incorrect columns: {set(record_dict[0].keys())}"
        assert (
            len(record_dict) == expected_rows
        ), f"Incorrect number of rows: {len(record_dict)}"


if __name__ == "__main__":
    pytest.main([__file__, "-sk", "test_update_records"])
