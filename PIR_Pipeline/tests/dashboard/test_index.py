import re
import pytest
import selenium
from flask import url_for
import urllib.request
from pir_pipeline.dashboard import create_app

@pytest.mark.usefixtures("create_database")
def test_get_home_page(client):
    '''Tests to ensure that the home page returns a valid HTML response with an appropriate title.'''
    response = client.get("/")
    assert response.status_code == 200, f"Expected 200 response from app, instead got {response.status_code}"
    expected_title = "<title>Home</title>"
    returned_title = re.search("<title>.*<\\/title>", response.text).group(0)
    assert returned_title == expected_title, f"Response from index did not return expected result, {expected_title}. Instead got {returned_title}."
   
if __name__ == "__main__":
    pytest.main([__file__, '-s'])