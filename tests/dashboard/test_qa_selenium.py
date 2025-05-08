import time

import pytest
from selenium import webdriver
from selenium.common.exceptions import TimeoutException
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.support.ui import WebDriverWait


@pytest.fixture
def driver():
    driver = webdriver.Firefox()
    yield driver
    driver.quit()


def test_search_button(driver):
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
    initial_rows = driver.find_elements(By.CSS_SELECTOR, "#flashcard-matches-table tr")

    # Wait for the input box and enter a search term
    search_input = WebDriverWait(driver, 10).until(
        EC.visibility_of_element_located((By.ID, "keyword-search"))
    )
    search_input.send_keys("children" + Keys.RETURN)

    WebDriverWait(driver, 10).until(
        EC.presence_of_element_located((By.ID, "flashcard-matches-table"))
    )
    WebDriverWait(driver, 10).until(
        lambda d: len(d.find_elements(By.CSS_SELECTOR, "#flashcard-matches-table tr"))
        > len(initial_rows)
    )

    rows = driver.find_elements(By.CSS_SELECTOR, "#flashcard-matches-table tr")

    # Asserts the search results exist in the table
    assert len(rows) > len(initial_rows), "No search results found in the table."

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
    time.sleep(5)

    # Click the 'Previous' button
    prev_button = driver.find_element(
        By.CSS_SELECTOR, 'form#flashcard-buttons button[value="previous"]'
    )
    prev_button.click()
    time.sleep(5)

    # Extract the Question ID
    question_id_element = driver.find_element(
        By.CSS_SELECTOR, '#flashcard-question-table td[name="question_id"]'
    )

    question_id = question_id_element.get_attribute("textContent").strip()

    assert (
        init_question_id == question_id
    ), "Previous and Next buttons are not working fine"

    # Count rows in modal table before clicking storeLink
    def count_modal_rows():
        return len(driver.find_elements(By.CSS_SELECTOR, "#flashcard-matches-table tr"))

    rows_before = WebDriverWait(driver, 10).until(lambda d: count_modal_rows())

    # Click the storeLink button in the first row
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
    rows_after = count_modal_rows()

    # Assert the function of the + symbol
    assert (
        rows_after == rows_before - 1
    ), "Row count did not change after clicking storeLink."
    time.sleep(5)

    # Count rows in modal table before clicking storeLink
    def count_modal_rows():
        return len(
            driver.find_elements(By.CSS_SELECTOR, "#flashcard-question-table tr")
        )

    rows_before = WebDriverWait(driver, 10).until(lambda d: count_modal_rows())

    storelink_button = WebDriverWait(driver, 10).until(
        EC.element_to_be_clickable(
            (
                By.XPATH,
                '//tr[@id="flashcard-matches-table-tr-0"]//button[@onclick="storeLink(event)"]',
            )
        )
    )
    storelink_button.click()
    time.sleep(5)

    # Count rows again after clicking
    rows_after = count_modal_rows()
    # Final assertion the function of the X symbol
    assert (
        rows_after == rows_before - 1
    ), "Row count did not change after clicking storeLink."
