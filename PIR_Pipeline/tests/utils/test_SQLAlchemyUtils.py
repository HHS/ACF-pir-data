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

    def test_insert_records(self, mock_data, sql_utils):
        insertable = mock_data().generate_data().export(how="Insertable")
        validation = {}
        for workbook in insertable._data.values():
            for table, data in workbook.items():
                if validation.get(table):
                    validation[table] += data.shape[0]
                else:
                    validation[table] = data.shape[0]

                records = data.to_dict(orient="records")
                sql_utils.insert_records(records, table)

        for table in validation:
            with sql_utils._engine.connect() as conn:
                result = conn.execute(text(f"SELECT COUNT(*) FROM {table}"))
                record_count = result.first()[0]

            assert record_count == validation[table]

    def test_get_records(self):
        pass

    def test_update_records(self):
        pass

    def test_to_dict(self):
        pass


if __name__ == "__main__":
    pytest.main([__file__, "-sk", "test_insert_records"])
