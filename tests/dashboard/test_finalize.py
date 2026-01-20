import re
import time

import pytest
from selenium.webdriver.common.by import By
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.support.ui import WebDriverWait
from sqlalchemy import select


@pytest.fixture
def propose_changes(server, driver, sql_utils):
    wait = WebDriverWait(driver, 10)
    driver.get("http://127.0.0.1:5000/review")
    records = sql_utils.get_records(select(sql_utils.tables["flashcard"]))
    while not records.empty:
        wait.until(EC.presence_of_element_located((By.ID, "flashcard-question-table")))
        confirm_button = driver.find_element(By.ID, "confirm-button")
        wait.until(EC.presence_of_element_located((By.ID, "confirm-button")))
        confirm_button.click()
        records = sql_utils.get_records(select(sql_utils.tables["flashcard"]))
        time.sleep(2)


@pytest.mark.usefixtures(
    "create_database", "app", "error_message_constructor", "propose_changes"
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

    def test_post_data(self, client, driver):
        with client.session_transaction() as sess:
            sess["number_displayed"] = 5

        with client:
            # Test if direction is none
            response = client.post("/finalize/data", json={})
            data = response.json
            qid = data["0"]["link_dict"][0]["base_question_id"]
            assert qid == "5f50241087df4b86810c044c4777566f50ae7453"
            assert len(data.keys()) == 5
            # Test if direction is next
            response = client.post("/finalize/data", json={"direction": "next"})
            data = response.json
            qid = data["0"]["link_dict"][0]["base_question_id"]
            assert qid == "d27e8217ba30000a78e5d92ea54f4d9a2e69cb54"
            assert len(data.keys()) == 1
            # Test if direction is previous
            response = client.post("/finalize/data", json={"direction": "previous"})
            data = response.json
            qid = data["0"]["link_dict"][0]["base_question_id"]
            assert qid == "5f50241087df4b86810c044c4777566f50ae7453"
            assert len(data.keys()) == 5
            # Test if direction is none
            response = client.post("/finalize/data", json={"direction": "previous"})
            data = response.json
            qid = data["0"]["link_dict"][0]["base_question_id"]
            assert qid == "d27e8217ba30000a78e5d92ea54f4d9a2e69cb54"
            assert len(data.keys()) == 1


if __name__ == "__main__":
    pytest.main([__file__, "-sk", "test_post_data"])
