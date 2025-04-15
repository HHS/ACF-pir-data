import re
import json

import pytest

@pytest.mark.usefixtures("create_database", "app")
def test_get_search_page(client):
    response = client.get("/search/")
    assert response.status_code == 200, f"Expected 200 response from app, instead got {response.status_code}"
    expected_title = "<title>Search</title>"
    returned_title = re.search("<title>.*<\\/title>", response.text).group(0)
    assert returned_title == expected_title, f"Response from search did not return expected result, {expected_title}. Instead got {returned_title}."
    
def test_post_search_returns_result(client):
    response = client.post("/search/",
                           data = {
                                    "column-select": "Category",
                                    "type-select": "unlinked",
                                    "keyword-search": ".*"
                            })
    assert response.status_code == 200, f"response.status_code for search function returned {response.status_code}."
    expected_unlinked_qid = "83e32d72b46030e1abf5109b8b506fb8"
    assert expected_unlinked_qid in response.text, f"Expected QID for unlinked record ({expected_unlinked_qid}) not found in search response."
    
def test_review_button_response(client):
    unlinked_id_to_test = "83e32d72b46030e1abf5109b8b506fb8"
    expected_qid_match_result = "87fe124509e4e9e48b26a65b78c87acd"
    response = client.post("/search/", 
                           data = {
                            "column-select": "Category",
                            "type-select": "unlinked",
                            "keyword-search": ".*"
                           })
    parsed_response = json.loads(response.text)
    # response.text is a dictionary of lists
    review_query = parsed_response[unlinked_id_to_test][0]
    review_query.update({"review-type": "unlinked"})
    
    # /search/data provides the same response as pressing the "Review" button for the associated record
    response = client.post("/search/data",
                        json = review_query)
    parsed_response = json.loads(response.text)
    
    assert all([key in parsed_response.keys() for key in ['matches', 'question']]), f"Expected response keys ['matches', 'question'], got {parsed_response.keys()}"
    assert expected_qid_match_result in parsed_response['matches'].keys(), f"Expected matches to contain qid: {expected_qid_match_result}"


if __name__ == "__main__":
    pytest.main([__file__, '-sk', ''])