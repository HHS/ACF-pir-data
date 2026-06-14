import pandas as pd
import pytest
from sqlalchemy import select

from pir_pipeline.query import helpers


@pytest.mark.usefixtures(
    "create_database",
    "insert_question_records",
    "insert_program_records",
    "insert_response_records",
)
class TestHelpers:
    def test_get_qids(self, sql_utils):
        result = helpers.get_qids(
            sql_utils,
            [
                {"question_number": "B.18.d-1", "year": 2023},
                {
                    "question_number": "B.18.d-1",
                    "year": 2024,
                },  # Should have same uqid as above
                {"question_number": "A.21.k-1", "year": 2009},
                {"question_number": "B.5-4", "year": 2011},
            ],  # Should have no uqid
        )

        assert (
            set(result["question_id"]).symmetric_difference(
                {
                    "443a354c772a24df0c2bba9acf568576a3b7d182",
                    "d27e8217ba30000a78e5d92ea54f4d9a2e69cb54",
                    "dd089009542dfd51e45f2f23826dbc7a6f6a912e",
                    "0e93c25d3a95604f40d3a64e2298093b4faed6f2",
                }
            )
            == set()
        ), "Question IDs are incorrect."
        assert (
            set(result["uqid"]).symmetric_difference(
                {
                    "e358fa167d3a9d5872f563ec5cfa07898a7ee186",
                    "6c9f2d2dcd01048e5163e12a1f50cb8e7c926e43",
                }
            )
            == set()
        ), "UQIDs are incorrect."

    def test_question_cte(self, sql_utils):
        data = {
            "question": [
                {"question_number": "B.18.d-1", "year": 2023},
                {
                    "question_number": "B.18.d-1",
                    "year": 2024,
                },  # Should have same uqid as above
                {"question_number": "A.21.k-1", "year": 2009},
                {"question_number": "B.5-4", "year": 2011},  # Should have no uqid
            ]
        }
        query = helpers.question_cte(
            sql_utils,
            data,
        )
        ids = data["question"]
        df = pd.read_sql(select(query), sql_utils._engine, params=ids)
        assert set(df["uqid"].dropna().unique()) == set(ids["uqid"]), "Incorrect UQIDs"
        assert set(df["question_id"].unique()).difference(ids["question_id"]) == set(
            [
                "b5c2dd4e8fe4523405cfcd2753da583d669db2af",
                "5f50241087df4b86810c044c4777566f50ae7453",
            ]
        ), "Incorrect Question IDs"

    def test_program_cte(self, sql_utils):
        data = {"program_type": ["HS"], "year": [2011]}
        query = helpers.program_cte(sql_utils, data)
        df = pd.read_sql(select(query), sql_utils._engine, params=data)

        assert df.shape[0] == 6, "Incorrect number of records."

        data = {"program_type": ["HS"]}
        query = helpers.program_cte(sql_utils, data)
        df = pd.read_sql(select(query), sql_utils._engine, params=data)

        assert df.shape[0] == 7, "Incorrect number of records."

    def test_get_responses(self, sql_utils):
        data = {
            "program": {"program_type": ["EHS"], "year": [2011]},
            "question": [{"question_number": "A.27.k-1"}],
        }
        records = helpers.get_responses(sql_utils, data)
        assert len(records) == 1 and len(records[0]) == 33, "Incorrect shape."
        assert (
            records[0]["uid"] == "c27e16e43f9feaea33441d1857989a64cd439a52"
        ), "Incorrect UID"
        assert (
            records[0]["question_id"] == "b5c2dd4e8fe4523405cfcd2753da583d669db2af"
        ), "Incorrect Question ID"


if __name__ == "__main__":
    pytest.main([__file__, "-vv", "-s", "-k", "test_get_responses"])
