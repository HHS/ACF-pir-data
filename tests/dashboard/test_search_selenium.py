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
    driver.get("http://127.0.0.1:5000/search/")

    # Wait for the input box and enter a search term
    search_input = WebDriverWait(driver, 10).until(
        EC.visibility_of_element_located((By.ID, "keyword-search"))
    )
    search_input.send_keys("children" + Keys.RETURN)

    # Wait for the search results table and rows to appear
    WebDriverWait(driver, 10).until(
        EC.presence_of_element_located((By.ID, "search-results-table"))
    )
    WebDriverWait(driver, 10).until(
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
            question_id_value = qid_cell.text.strip()
            if question_id_value:
                first_data_row = row
                break
        except:
            continue

    # Asserts the valid question id exist in the table
    assert first_data_row is not None, "No valid row with a question_id was found."

    edit_button = WebDriverWait(driver, 10).until(
        EC.element_to_be_clickable(
            (
                By.XPATH,
                '//table[@id="search-results-table"]//button[@onclick="getFlashcardData(event)"]',
            )
        )
    )
    edit_button.click()

    # Wait for the modal to become visible
    try:
        WebDriverWait(driver, 10).until(
            lambda d: d.find_element(By.ID, "search-modal").get_attribute("hidden")
            is None
        )
        modal_visible = True
    except TimeoutException:
        modal_visible = False

    # Asserts the functionality of the edit button
    assert modal_visible, "Edit modal did not appear after clicking Edit button."

    # Count rows in modal table before clicking storeLink
    def count_modal_rows():
        return len(driver.find_elements(By.CSS_SELECTOR, "#flashcard-matches-table tr"))

    rows_before = WebDriverWait(driver, 10).until(lambda d: count_modal_rows())
    # print(f"Rows before clicking storeLink: {rows_before}")

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
    # print(f"Rows after clicking storeLink: {rows_after}")
    # print(rows_after == rows_before - 1)
    # Assert the function of the + symbol
    assert (
        rows_after == rows_before - 1
    ), "Row count did not change after clicking storeLink."

    # Count rows in modal table before clicking storeLink
    def count_modal_rows():
        return len(
            driver.find_elements(By.CSS_SELECTOR, "#flashcard-question-table tr")
        )

    rows_before = WebDriverWait(driver, 10).until(lambda d: count_modal_rows())
    # print(f"Rows before clicking storeLink: {rows_before}")

    storelink_button = WebDriverWait(driver, 10).until(
        EC.element_to_be_clickable(
            (
                By.XPATH,
                '//tr[@id="flashcard-matches-table-tr-0"]//button[@onclick="storeLink(event)"]',
            )
        )
    )
    storelink_button.click()
    # Count rows again after clicking
    rows_after = count_modal_rows()
    # print(f"Rows after clicking storeLink: {rows_after}")
    # print(rows_after == rows_before - 1)
    # Final assertion or output
    # Assert the function of the X symbol
    assert (
        rows_after == rows_before - 1
    ), "Row count did not change after clicking storeLink."
