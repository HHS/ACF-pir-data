import os
import time

import pytest
from selenium.common.exceptions import TimeoutException
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.support.ui import WebDriverWait
from sqlalchemy import text


@pytest.mark.skipif(
    bool(os.getenv("ON_RUNNER")), reason="Test does not run on GitHub runner"
)
@pytest.mark.usefixtures("create_database", "insert_question_records", "server")
def test_search_ui(driver, sql_utils):
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

    driver.get("http://127.0.0.1:5000/search/")

    # Wait for the input box and enter a search term
    wait = WebDriverWait(driver, 10)
    search_input = wait.until(
        EC.visibility_of_element_located((By.ID, "keyword-search"))
    )
    search_input.send_keys("child" + Keys.RETURN)

    # Wait for the search results table and rows to appear
    wait.until(EC.presence_of_element_located((By.ID, "search-results-table")))
    wait.until(
        lambda d: len(d.find_elements(By.CSS_SELECTOR, "#search-results-table tr")) > 0
    )

    # Get all rows and pick the first data row (skip header if present)
    rows = driver.find_elements(By.CSS_SELECTOR, "#search-results-table tr")

    # Asserts the search results exist in the table
    assert len(rows) > 0, "No search results found in the table."

    first_data_row = None

    for row in rows:
        try:
            qid_cell = row.find_element(By.CSS_SELECTOR, 'td[name="question_id"]')
            question_id_value = qid_cell.get_attribute("textContent").strip()
            if question_id_value:
                first_data_row = row
                break
        except Exception:
            continue

    # Asserts the valid question id exist in the table
    assert first_data_row is not None, "No valid row with a question_id was found."

    edit_button = wait.until(
        EC.element_to_be_clickable(
            (
                By.CSS_SELECTOR,
                "tr[id='search-results-table-tr-10002'] button[onclick='getFlashcardData(event)']",
            )
        )
    )
    edit_button.click()

    # Wait for the modal to become visible
    try:
        wait.until(
            lambda d: d.find_element(By.ID, "search-modal").get_attribute("hidden")
            is None
        )
        modal_visible = True
    except TimeoutException:
        modal_visible = False

    # Asserts the functionality of the edit button
    assert modal_visible, "Edit modal did not appear after clicking Edit button."

    # Click the storeLink button in the first row
    question_rows_init = count_modal_rows("question")
    match_rows_init = count_modal_rows("matches")
    storelink_button = wait.until(
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

    storelink_button = wait.until(
        EC.element_to_be_clickable(
            (
                By.XPATH,
                '//tr[@id="flashcard-matches-table-tr-10000"]//button[@onclick="storeLink(event)"]',
            )
        )
    )
    storelink_button.click()

    match_rows_x = count_modal_rows("matches")
    question_rows_x = count_modal_rows("question")

    # Final assertion the function of the X symbol
    assert (
        match_rows_init == match_rows_x
    ), f"Count before: {match_rows_init}; Count after: {match_rows_plus}"
    assert (
        question_rows_init == question_rows_x
    ), f"Count before: {match_rows_init}; Count after: {match_rows_plus}"

    # Check confirm button
    storelink_button = wait.until(
        EC.element_to_be_clickable(
            (
                By.XPATH,
                '//table[@id="flashcard-matches-table"]//button[@onclick="storeLink(event)"]',
            )
        )
    )
    storelink_button.click()
    init_question_ids = driver.find_elements(
        By.CSS_SELECTOR, '#flashcard-question-table td[name="question_id"]'
    )
    init_question_ids = set(
        [question.get_attribute("textContent") for question in init_question_ids]
    )

    confirm_button = driver.find_element(value="confirm-button")
    confirm_button.click()

    with sql_utils.engine.connect() as conn:
        result = conn.execute(text("SELECT question_id FROM uqid_changelog"))
        question_ids = result.scalars()

    question_ids = set(question_ids)

    assert question_ids.issuperset(
        init_question_ids
    ), f"question_id set is not a superset of init_question_id set {question_ids.symmetric_difference(init_question_ids)}"


if __name__ == "__main__":
    pytest.main([__file__, "-sk", "test_search_ui"])
