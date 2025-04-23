import json
import re

import pytest
from flask import session
from sqlalchemy import func, select


@pytest.mark.usefixtures("create_database", "app", "error_message_constructor")
class TestReviewRoutes:
    def test_get_index(self, client):
        response = client.get("/review/")
        assert (
            response.status_code == 200
        ), f"Expected 200 response from app, instead got {response.status_code}"

        expected_title = "<title>Review</title>"
        returned_title = re.search("<title>.*<\\/title>", response.text).group(0)
        assert (
            returned_title == expected_title
        ), f"Response from review did not return expected result, {expected_title}. Instead got {returned_title}."

    def test_get_finalize(self, client, question_linker_payload):
        with client.session_transaction() as session:
            session["link_dict"] = question_linker_payload

        response = client.get("/review/finalize")
        assert (
            response.status_code == 200
        ), f"Got non-200 response code: {response.status_code}"

        assert (
            '<button class="btn btn-primary" type="submit" name="action" value="commit">Commit All Changes to the Database</button>'
            in response.text
        ), "Commit button is missing"

    def test_get_flashcard(self, client):
        response = client.get("/review/flashcard")
        assert (
            response.status_code == 200
        ), f"Got non-200 response code: {response.status_code}"

        assert (
            '<button class="btn btn-primary" type="submit" name="action" value="previous">Previous</button>'
            in response.text
        ), "Previous button is missing from page"

    def test_post_flashcard(self, client, sql_utils, error_message_constructor):
        with client.session_transaction() as sess:
            sess["current_question"] = 0
            with sql_utils.engine.connect() as conn:
                result = conn.execute(
                    select(func.count(sql_utils.tables["unconfirmed"].c["question_id"]))
                )
                sess["max_questions"] = result.scalar() - 1

        response = client.post("/review/flashcard", data={"action": "next"})
        data = json.loads(response.text)
        question = data["question"]
        expected_name = "Total Family Child Care Providers"
        actual_name = question[list(question.keys())[1]][0]["question_name"]

        assert actual_name == expected_name, error_message_constructor(
            "Incorrect question_name", expected_name, actual_name
        )

        response = client.post("/review/flashcard", data={"action": "previous"})
        data = json.loads(response.text)
        question = data["question"]
        expected_name = "Other Languages"
        actual_name = question[list(question.keys())[1]][0]["question_name"]

        assert actual_name == expected_name, error_message_constructor(
            "Incorrect question_name", expected_name, actual_name
        )

        response = client.post("/review/flashcard", data={"action": "finish"})
        assert (
            response.headers["Location"] == "/review/finalize"
        ), "Did not redirect to finalize"

    def test_post_data(self, client, error_message_constructor):
        response = client.post("/review/data", json={"for": "flashcard"})
        assert (
            response.status_code == 200
        ), f"Got non-200 response code: {response.status_code}"

        data = json.loads(response.text)
        question = data["question"]
        expected_name = "Other Languages"
        actual_name = question[list(question.keys())[1]][0]["question_name"]

        assert expected_name == actual_name, error_message_constructor(
            "Incorrect question_name", expected_name, actual_name
        )

    def test_post_link(self, client):
        with client:
            client.post("/review/link", json={"action": "build", "data": {"A": "B"}})
            assert session["link_dict"][list(session["link_dict"].keys())[-1]] == {
                "A": "B"
            }

    def test_post_finalize(self, client, question_linker_payload, sql_utils):
        with client.session_transaction() as sess:
            sess["link_dict"] = question_linker_payload

        # Remove a record
        with client:
            response = client.post(
                "/review/finalize", data={"action": "remove", "finalize-id": "1"}
            )
            assert (
                response.status_code == 200
            ), f"Got non-200 response code: {response.status_code}"

            assert set(session["link_dict"].keys()) == {"2", "3", "4", "5"}

        # Commit changes
        response = client.post("/review/finalize", data={"action": "commit"})

        uqid_changelog = sql_utils.tables["uqid_changelog"]
        with sql_utils.engine.connect() as conn:
            result = conn.execute(
                select(uqid_changelog).where(
                    uqid_changelog.c["original_uqid"]
                    == question_linker_payload["5"]["base_uqid"]
                )
            )
            record = result.one()

            assert record[5] == 1, f"Flag is False: {record[5]}"


if __name__ == "__main__":
    pytest.main([__file__, "-sk", "test_post_link"])
