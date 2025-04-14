import os
import tempfile
import re
import pytest
from pir_pipeline.dashboard import create_app

@pytest.mark.usefixtures("app", "create_database")
def test_request_home_page(client):
    response = client.get("/")
    expected_title = "<title>Home</title>"
    returned_title = re.search("<title>.*<\\/title>", response.text).group(0)
    assert response, "No response from client.get()"
    assert returned_title == expected_title, f"Response from index did not return expected result, {expected_title}. Instead got {returned_title}."
   
if __name__ == "__main__":
    pytest.main([__file__, '-sk', ''])