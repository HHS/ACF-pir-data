import re

import pytest


@pytest.fixture(scope="class")
def insert_records(client):
    qids = [
        "443a354c772a24df0c2bba9acf568576a3b7d182",
        "d27e8217ba30000a78e5d92ea54f4d9a2e69cb54",
        "dd089009542dfd51e45f2f23826dbc7a6f6a912e",
        "b5c2dd4e8fe4523405cfcd2753da583d669db2af",
        "5f50241087df4b86810c044c4777566f50ae7453",
        "8e96da390b28ba6f5571ee1f68716cca982ccca0",
    ]
    input_records = [
        {
            f"{i}": {
                "link_type": "confirm",
                "base_question_id": f"{qids[i]}",
                "match_question_id": "",
            }
        }
        for i in range(6)
    ]
    for record in input_records:
        with client.session_transaction() as sess:
            sess["link_dict"] = record

        client.post(
            "/review/link",
            json={
                "action": "store",
                "html": "",
            },
        )


@pytest.fixture(scope="class")
def set_number_displayed(client):
    with client.session_transaction() as sess:
        sess["number_displayed"] = 5


@pytest.mark.usefixtures(
    "create_database",
    "app",
    "error_message_constructor",
    "insert_records",
    "set_number_displayed",
)
class TestFinalizeRoutes:
    def test_get_index(self, client):
        response = client.get("/finalize/")
        assert (
            response.status_code == 200
        ), f"Expected 200 response from app, instead got {response.status_code}"

        expected_title = "<title>Finalize</title>"
        returned_title = re.search("<title>.*<\\/title>", response.text).group(0)
        assert (
            returned_title == expected_title
        ), f"Response from finalize did not return expected result, {expected_title}. Instead got {returned_title}."

    def test_post_data(self, client):
        with client:
            # Test if direction is none
            response = client.post(
                "/finalize/data", json={}, headers={"Content-Type": "application/json"}
            )
            data = response.json
            qid = data["0"]["link_dict"][0]["base_question_id"]
            assert qid == "443a354c772a24df0c2bba9acf568576a3b7d182"
            assert len(data.keys()) == 5
            # Test if direction is next
            response = client.post(
                "/finalize/data",
                json={"direction": "next"},
                headers={"Content-Type": "application/json"},
            )
            data = response.json
            qid = data["0"]["link_dict"][0]["base_question_id"]
            assert qid == "8e96da390b28ba6f5571ee1f68716cca982ccca0"
            assert len(data.keys()) == 1
            # Test if direction is previous
            response = client.post("/finalize/data", json={"direction": "previous"})
            data = response.json
            qid = data["0"]["link_dict"][0]["base_question_id"]
            assert qid == "443a354c772a24df0c2bba9acf568576a3b7d182"
            assert len(data.keys()) == 5
            # Test wrapping
            response = client.post("/finalize/data", json={"direction": "previous"})
            data = response.json
            qid = data["0"]["link_dict"][0]["base_question_id"]
            assert qid == "8e96da390b28ba6f5571ee1f68716cca982ccca0"
            assert len(data.keys()) == 1


if __name__ == "__main__":
    pytest.main([__file__, "-sk", "test_post_data"])
