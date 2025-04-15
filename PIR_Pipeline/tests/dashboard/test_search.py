import re

import pytest

@pytest.mark.usefixtures("app", "create_database")
def test_get_search_page(client):
    response = client.get("/search")
    assert response.status_code == 200, f"Expected 200 response from app, instead got {response.status_code}"
    expected_title = "<title>Search</title>"
    returned_title = re.search("<title>.*<\\/title>", response.text).group(0)
    assert returned_title == expected_title, f"Response from index did not return expected result, {expected_title}. Instead got {returned_title}."

if __name__ == "__main__":
    pytest.main([__file__, '-sk', ''])