import json
import sys

import pytest

from pir_pipeline.config import DB_CONFIG
from pir_pipeline.query.cli import PirQuery


@pytest.mark.usefixtures(
    "create_database",
    "insert_question_records",
    "insert_program_records",
    "insert_response_records",
    "insert_agency_id_records",
)
class TestCli:
    def test_one_query(self, tmp_path):
        data_path = tmp_path / "temp.json"
        credential_path = tmp_path / "creds.json"

        with open(data_path, "w") as f:
            json.dump(
                {
                    "program": {"program_type": ["EHS"], "year": [2011]},
                    "question": [{"question_number": "A.27.k-1"}],
                    "aggregate_by": [],
                },
                f,
            )

        config = DB_CONFIG.copy()
        config.update({"database": "pir_test"})

        with open(credential_path, "w") as f:
            json.dump(config, f)

        sys.argv = ["pir-query", str(data_path), str(credential_path)]
        pir_query = PirQuery()
        pir_query.disaggregate_queries(pir_query.data)
        assert (
            len(pir_query.records) == 3 and len(pir_query.records[0]) == 30
        ), "Incorrect shape."
        assert (
            pir_query.records[0]["uid"] == "c27e16e43f9feaea33441d1857989a64cd439a52"
        ), "Incorrect UID"
        assert (
            pir_query.records[0]["question_id"]
            == "b5c2dd4e8fe4523405cfcd2753da583d669db2af"
        ), "Incorrect Question ID"

    def test_multiple_queries(self):
        pass


if __name__ == "__main__":
    pytest.main([__file__, "-vv", "-s", "-k", "test_one_query"])
