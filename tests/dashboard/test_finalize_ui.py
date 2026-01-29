import os
import time

import pytest
from selenium.webdriver import Firefox
from selenium.webdriver.common.by import By
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.support.ui import Select, WebDriverWait
from sqlalchemy import select

from pir_pipeline.utils.SQLAlchemyUtils import SQLAlchemyUtils


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
        time.sleep(1)


@pytest.mark.skipif(
    bool(os.getenv("ON_RUNNER")), reason="Test does not run on GitHub runner"
)
@pytest.mark.usefixtures(
    "create_database", "insert_question_records", "server", "propose_changes"
)
class TestFinalizeUI:
    def test_pagination(self, driver: Firefox, error_message_constructor, client):
        driver.get("http://127.0.0.1:5000/finalize")
        number_displayed = driver.find_element(By.ID, "number-displayed")
        Select(number_displayed).select_by_value("5")
        wait = WebDriverWait(driver, 10)
        # Go to next page and confirm 1 record
        next_button = driver.find_element(By.ID, "next-button")
        next_button.click()
        wait.until(EC.presence_of_element_located((By.TAG_NAME, "table")))
        tables = driver.find_elements(By.TAG_NAME, "table")
        expected = 1
        got = len(tables)
        assert expected == got, error_message_constructor(
            "Incorrect number of tables", expected, got
        )

        # Go to next page and confirm 5 records
        next_button = driver.find_element(By.ID, "next-button")
        next_button.click()
        wait.until(EC.presence_of_element_located((By.TAG_NAME, "table")))
        tables = driver.find_elements(By.TAG_NAME, "table")
        expected = 5
        got = len(tables)
        assert expected == got, error_message_constructor(
            "Incorrect number of tables", expected, got
        )

        # Go to previous page and confirm 1 record
        previous_button = driver.find_element(By.ID, "previous-button")
        previous_button.click()
        wait.until(EC.presence_of_element_located((By.TAG_NAME, "table")))
        tables = driver.find_elements(By.TAG_NAME, "table")
        expected = 1
        got = len(tables)
        assert expected == got, error_message_constructor(
            "Incorrect number of tables", expected, got
        )

    def test_action_buttons(
        self, driver: Firefox, sql_utils: SQLAlchemyUtils, error_message_constructor
    ):
        driver.get("http://127.0.0.1:5000/finalize")
        wait = WebDriverWait(driver, 10)

        wait.until(EC.presence_of_element_located((By.CLASS_NAME, "deny-button")))
        deny_button = driver.find_element(By.CLASS_NAME, "deny-button")
        deny_button.click()

        proposed_changes_query = select(sql_utils.tables["proposed_changes"])

        with sql_utils.engine.connect() as conn:
            response = conn.execute(proposed_changes_query)
            proposed_changes = response.all()

        expected = 5
        got = len(proposed_changes)
        assert expected == got, error_message_constructor(
            "Incorrect number of records", expected, got
        )

        wait.until(
            EC.presence_of_element_located((By.CSS_SELECTOR, "button[name='confirm']"))
        )
        confirm_button = driver.find_element(By.CSS_SELECTOR, "button[name='confirm']")
        confirm_button.click()

        with sql_utils.engine.connect() as conn:
            response = conn.execute(proposed_changes_query)
            proposed_changes = response.all()

        expected = 4
        got = len(proposed_changes)
        assert expected == got, error_message_constructor(
            "Incorrect number of records", expected, got
        )


if __name__ == "__main__":
    pytest.main([__file__, "-sk", "test_pagination"])
