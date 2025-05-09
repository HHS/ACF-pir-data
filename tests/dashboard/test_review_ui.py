import os
import signal
import threading
import time

import pytest
import requests
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.firefox.options import Options
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.support.ui import WebDriverWait

from pir_pipeline.config import DB_CONFIG
from pir_pipeline.dashboard import create_app


@pytest.fixture
def driver():
    options = Options()
    options.add_argument("--headless")
    driver = webdriver.Firefox(options=options)
    yield driver
    driver.quit()


@pytest.fixture
def server():
    config = {"DB_CONFIG": DB_CONFIG, "DB_NAME": "pir_test"}
    app = create_app(test_config=config)

    @app.route("/shutdown", methods=["POST"])
    def shutdown():
        os.kill(os.getpid(), signal.SIGTERM)
        return "Server shutting down..."

    proc = threading.Thread(target=app.run)
    yield proc.start()

    requests.post("http://localhost:5000/shutdown")
    proc.join()


@pytest.mark.usefixtures("create_database", "insert_question_records", "server")
def test_review_ui(driver):
    # Count rows in modal table before clicking storeLink
    def count_modal_rows(table: str):
        if table == "question":
            count = len(
                driver.find_elements(By.CSS_SELECTOR, "#flashcard-question-table tr")
            )
        elif table == "matches":
            count = len(
                driver.find_elements(By.CSS_SELECTOR, "#flashcard-matches-table tr")
            )

        return count

    driver.get("http://127.0.0.1:5000/review")

    # Wait for the search results table and rows to appear
    WebDriverWait(driver, 10).until(
        EC.presence_of_element_located((By.ID, "flashcard-matches-table"))
    )

    WebDriverWait(driver, 10).until(
        lambda d: len(d.find_elements(By.CSS_SELECTOR, "#flashcard-matches-table tr"))
        > 0
    )

    # Get all rows and pick the first data row
    # Wait for the input box and enter a search term
    search_input = WebDriverWait(driver, 10).until(
        EC.visibility_of_element_located((By.ID, "keyword-search"))
    )
    search_input.send_keys("child" + Keys.RETURN)

    WebDriverWait(driver, 10).until(
        EC.presence_of_element_located((By.ID, "flashcard-matches-table"))
    )
    WebDriverWait(driver, 10).until(
        lambda d: d.find_element(
            By.CSS_SELECTOR, "tr#flashcard-matches-table-tr-0 td[name='question_id']"
        ).get_attribute("textContent")
        == "0e93c25d3a95604f40d3a64e2298093b4faed6f2"
    )

    # Click the storeLink button in the first row

    question_rows_init = count_modal_rows("question")
    match_rows_init = count_modal_rows("matches")
    storelink_button = WebDriverWait(driver, 10).until(
        EC.element_to_be_clickable(
            (
                By.XPATH,
                '//table[@id="flashcard-matches-table"]//button[@onclick="storeLink(event)"]',
            )
        )
    )
    storelink_button.click()

    # Count rows again after clicking
    match_rows_plus = count_modal_rows("matches")
    question_rows_plus = count_modal_rows("question")

    # Assert the function of the + symbol
    assert (
        match_rows_plus < match_rows_init
    ), f"Count before: {match_rows_init}; Count after: {match_rows_plus}"
    assert (
        question_rows_plus > question_rows_init
    ), f"Count before: {match_rows_init}; Count after: {match_rows_plus}"
    time.sleep(1)

    storelink_button = WebDriverWait(driver, 10).until(
        EC.element_to_be_clickable(
            (
                By.XPATH,
                '//tr[@id="flashcard-matches-table-tr-0"]//button[@onclick="storeLink(event)"]',
            )
        )
    )
    storelink_button.click()
    time.sleep(1)

    match_rows_x = count_modal_rows("matches")
    question_rows_x = count_modal_rows("question")

    # Final assertion the function of the X symbol
    assert (
        match_rows_init == match_rows_x
    ), f"Count before: {match_rows_init}; Count after: {match_rows_plus}"
    assert (
        question_rows_init == question_rows_x
    ), f"Count before: {match_rows_init}; Count after: {match_rows_plus}"

    # Extract the Question ID
    question_id_element = driver.find_element(
        By.CSS_SELECTOR, '#flashcard-question-table td[name="question_id"]'
    )

    init_question_id = question_id_element.get_attribute("textContent").strip()

    # Wait until the form containing the buttons is present
    WebDriverWait(driver, 10).until(
        EC.presence_of_element_located((By.ID, "flashcard-buttons"))
    )

    # Click the 'Next' button
    next_button = driver.find_element(
        By.CSS_SELECTOR, 'form#flashcard-buttons button[value="next"]'
    )
    next_button.click()
    time.sleep(1)

    # Click the 'Previous' button
    prev_button = driver.find_element(
        By.CSS_SELECTOR, 'form#flashcard-buttons button[value="previous"]'
    )
    prev_button.click()
    time.sleep(1)

    # Extract the Question ID
    question_id_element = driver.find_element(
        By.CSS_SELECTOR, '#flashcard-question-table td[name="question_id"]'
    )

    question_id = question_id_element.get_attribute("textContent").strip()

    assert (
        init_question_id == question_id
    ), "Previous and Next buttons are not working fine"


if __name__ == "__main__":
    pytest.main([__file__, "-sk", "test_review_ui"])
