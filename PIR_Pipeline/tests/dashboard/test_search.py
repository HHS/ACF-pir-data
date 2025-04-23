import json
import re

import pytest
from flask import get_flashed_messages


@pytest.mark.usefixtures("create_database", "app")
class TestSearchRoutes:
    def test_get_search(self, client):
        """Tests to ensure that the search page returns the appropriately titled HTML response."""
        response = client.get("/search/")
        assert (
            response.status_code == 200
        ), f"Expected 200 response from app, instead got {response.status_code}"

        expected_title = "<title>Search</title>"
        returned_title = re.search("<title>.*<\\/title>", response.text).group(0)
        assert (
            returned_title == expected_title
        ), f"Response from search did not return expected result, {expected_title}. Instead got {returned_title}."

    def test_post_search(self, client, app):
        """Tests to ensure that a POST request with a query returns records."""
        response = client.post(
            "/search/",
            data={
                "keyword-search": "B.18.d-1",
            },
        )
        assert (
            response.status_code == 200
        ), f"response.status_code for search function returned {response.status_code}."

        data = json.loads(response.text)
        question_text = data[list(data.keys())[1]][0]["question_text"]
        assert (
            question_text == "Other (e.g., change in job field, reason not provided)"
        ), f"Incorrect question_text: {question_text}"

        # Confirm that no search term redirects to search
        with client:
            response = client.post("/search/", json={"error": "Invalid response"})
            assert get_flashed_messages() == ["Please enter a search term"]

    def test_post_data(self, client):
        """Tests that the response from /search/data returns the expected results.
        Sending a POST request to /search/data is meant to return values from the review page for the associated record.
        In this case, the qid values are found in tests/conftest.py"""

        unlinked_id_to_test = "83e32d72b46030e1abf5109b8b506fb8"
        expected_qid_match_result = "87fe124509e4e9e48b26a65b78c87acd"

        response = client.post(
            "/search/",
            data={
                "keyword-search": "83e32",
            },
        )
        parsed_response = json.loads(response.text)

        # response.text is a dictionary of lists
        review_query = parsed_response[unlinked_id_to_test][0]
        review_query.update({"review-type": "unlinked"})

        # /search/data provides the same response as pressing the "Review" button for the associated record
        response = client.post("/search/data", json=review_query)
        parsed_response = json.loads(response.text)

        assert all(
            [key in parsed_response.keys() for key in ["matches", "question"]]
        ), f"Expected response keys ['matches', 'question'], got {parsed_response.keys()}"
        assert (
            expected_qid_match_result in parsed_response["matches"].keys()
        ), f"Expected matches to contain qid: {expected_qid_match_result}"

    def test_get_flashcard(self, client):
        response = client.get("/search/flashcard")
        assert (
            """<script type="module" src="/static/search/flashcard.js"></script>"""
            in response.text
        ), "Incorrect response"

    def test_post_flashcard(self, client):
        response = client.post("/search/flashcard")
        location = response.headers["Location"]
        assert (
            location == "/review/finalize"
        ), f"Redirected to incorrect url: {location}"


if __name__ == "__main__":
    pytest.main([__file__, "-sk", "test_post_flashcard"])
