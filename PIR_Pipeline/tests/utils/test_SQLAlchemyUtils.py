import numpy as np
import pytest
from sqlalchemy import select, text

from pir_pipeline.config import db_config
from pir_pipeline.utils.SQLAlchemyUtils import SQLAlchemyUtils


@pytest.mark.usefixtures("create_database")
class TestSQLAlchemyUtils:
    def test_gen_engine(self):
        db_config.update({"username": db_config["user"]})
        db_config.pop("user")
        query = select(text("'Connection Made'"))
        with SQLAlchemyUtils.__new__(SQLAlchemyUtils).gen_engine(
            **db_config, database="pir_test", drivername="postgresql+psycopg"
        )._engine.connect() as conn:
            result = conn.execute(query)
            value = result.first()

        assert value[0] == "Connection Made", "Incorrect value."

    # How to test this and drop_db when it is in the fixture?
    def test_create_db(self):
        pass

    def test_drop_db(self):
        pass

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

    def test_get_records(self, insertable, db_columns, sql_utils):
        for workbook in insertable._data.values():
            for table, data in workbook.items():
                data.replace({np.nan: None}, inplace=True)
                records = data.to_dict(orient="records")
                sql_utils.insert_records(records, table)

        queries = [
            (
                "SELECT * FROM response",
                self.validation["response"],
                db_columns["response"],
            ),
            (
                "SELECT * FROM question WHERE section = 'A'",
                self.validation["question"] / 4,
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

    def test_update_records(self):
        pass

    def test_to_dict(self):
        pass


if __name__ == "__main__":
    pytest.main([__file__, "-sk", "test_get_records"])
