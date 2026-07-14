import pytest
import requests


@pytest.mark.usefixtures(
    "create_database",
    "create_database",
    "insert_question_records",
    "insert_program_records",
    "insert_response_records",
    "app",
)
class TestCoreRoutes:
    def test_query(self, client):
        # No aggregation
        response = client.post(
            "/query",
            json={
                "program": {"program_type": ["EHS"], "year": [2011]},
                "question": [{"question_number": "A.27.k-1"}],
                "aggregate_by": [],
            },
        )
        response = requests.get(response.text)
        records = response.json()
        assert len(records) == 3 and len(records[0]) == 27, "Incorrect shape"
        assert records[0]["grant_number"] == "01CH0002", "Incorrect Grant Number"
        assert records[0]["question_number"] == "A.22.k-1", "Incorrect Question Number"

        # Aggregate by program type
        response = client.post(
            "/query",
            json={
                "program": {"program_type": ["EHS"], "year": [2011]},
                "question": [{"question_number": "B.5-4"}],
                "aggregate_by": ["program_type"],
            },
        )
        response = requests.get(response.text)
        records = response.json()
        assert len(records) == 1 and len(records[0]) == 12, "Incorrect shape"
        assert records[0]["answer"] == 10, "Incorrect answer value."

        # Aggregate by grant and program type
        response = client.post(
            "/query",
            json={
                "program": {},
                "question": [{"question_number": "B.5-4"}],
                "aggregate_by": ["program_type"],
            },
        )
        response = requests.get(response.text)
        records = response.json()
        assert (
            len(records) == 3 and len(records[0]) == 12
        ), "Incorrect shape."  # Two different uqids leads to 3 records despite 2 program types
        assert records[0]["answer"] == 10, "Incorrect answer value."


if __name__ == "__main__":
    pytest.main([__file__, "-sk", "test_query"])
