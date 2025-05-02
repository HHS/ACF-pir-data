import pytest
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import TimeoutException

@pytest.fixture
def driver():
    driver = webdriver.Firefox()
    yield driver
    driver.quit()

def test_search_results_exist(driver):
    driver.get("http://127.0.0.1:5000/search/")

    # Wait for the input box and enter a search term
    search_input = WebDriverWait(driver, 10).until(
        EC.visibility_of_element_located((By.ID, "keyword-search"))
    )
    search_input.send_keys("children" + Keys.RETURN)

    # Wait for the search results table to appear
    WebDriverWait(driver, 10).until(
        EC.presence_of_element_located((By.ID, "search-results-table"))
    )

    # Wait for rows to appear in the table (up to 10 seconds)
    WebDriverWait(driver, 10).until(
        lambda d: len(d.find_elements(By.CSS_SELECTOR, "#search-results-table tr")) > 0
    )

    rows = driver.find_elements(By.CSS_SELECTOR, "#search-results-table tr")
    assert len(rows) > 0, "No search results found in the table."


def test_edit_search_results_exist(driver):
    driver.get("http://127.0.0.1:5000/search/")

    # Wait for the input box and enter a search term
    search_input = WebDriverWait(driver, 10).until(
        EC.visibility_of_element_located((By.ID, "keyword-search"))
    )
    search_input.send_keys("children" + Keys.RETURN)

    # Wait for the search results table to appear
    WebDriverWait(driver, 10).until(
        EC.presence_of_element_located((By.ID, "search-results-table"))
    )

    # Wait for rows to load
    WebDriverWait(driver, 10).until(
        lambda d: len(d.find_elements(By.CSS_SELECTOR, "#search-results-table tr")) > 0
    )

    # Locate the correct row by matching question_id
    question_id_value = "00dc7ace2a6c22227996a991c9f52157"
    rows = driver.find_elements(By.CSS_SELECTOR, "#search-results-table tr")

    matched_row = None
    for row in rows:
        try:
            qid_cell = row.find_element(By.CSS_SELECTOR, 'td[name="question_id"]')
            if qid_cell.text.strip() == question_id_value:
                matched_row = row
                break
        except:
            continue

    assert matched_row is not None, f"No row found with question_id = {question_id_value}"

    # Click the edit button inside that matched row
    edit_button = matched_row.find_element(By.XPATH, './/button[@onclick="getFlashcardData(event)"]')
    edit_button.click()

    # Wait for the modal to become visible
    try:
        WebDriverWait(driver, 10).until(
            lambda d: d.find_element(By.ID, "search-modal").get_attribute("hidden") is None
        )
        modal_visible = True
    except TimeoutException:
        modal_visible = False

    assert modal_visible, "Edit modal did not appear after clicking Edit button."

def test_storelink_button_effect(driver):
    driver.get("http://127.0.0.1:5000/search/")

    # Perform search
    search_input = WebDriverWait(driver, 10).until(
        EC.visibility_of_element_located((By.ID, "keyword-search"))
    )
    search_input.send_keys("children" + Keys.RETURN)

    # Wait for search results and click first edit button
    WebDriverWait(driver, 10).until(
        EC.presence_of_element_located((By.ID, "search-results-table"))
    )

    WebDriverWait(driver, 10).until(
        lambda d: len(d.find_elements(By.CSS_SELECTOR, "#search-results-table tr")) > 0
    )

    edit_button = WebDriverWait(driver, 10).until(
        EC.element_to_be_clickable((By.XPATH, '//table[@id="search-results-table"]//button[@onclick="getFlashcardData(event)"]'))
    )
    edit_button.click()

    # Wait for modal to be visible
    WebDriverWait(driver, 10).until(
        lambda d: d.find_element(By.ID, "search-modal").get_attribute("hidden") is None
    )

    # Count rows in modal table before clicking storeLink
    def count_modal_rows():
        return len(driver.find_elements(By.CSS_SELECTOR, "#flashcard-matches-table tr"))

    rows_before = WebDriverWait(driver, 10).until(lambda d: count_modal_rows())
    print(f"Rows before clicking storeLink: {rows_before}")

    # Click the storeLink button in the first row
    storelink_button = WebDriverWait(driver, 10).until(
        EC.element_to_be_clickable((By.XPATH, '//table[@id="flashcard-matches-table"]//button[@onclick="storeLink(event)"]'))
    )
    storelink_button.click()

    # Count rows again after clicking
    rows_after = count_modal_rows()
    print(f"Rows after clicking storeLink: {rows_after}")
    print(rows_after == rows_before-1)
    # Final assertion or output
    assert rows_after == rows_before-1, "Row count did not change after clicking storeLink."

def test_storelink_button_x_effect(driver):
    driver.get("http://127.0.0.1:5000/search/")

    # Perform search
    search_input = WebDriverWait(driver, 10).until(
        EC.visibility_of_element_located((By.ID, "keyword-search"))
    )
    search_input.send_keys("children" + Keys.RETURN)

    # Wait for search results and click first edit button
    WebDriverWait(driver, 10).until(
        EC.presence_of_element_located((By.ID, "search-results-table"))
    )

    WebDriverWait(driver, 10).until(
        lambda d: len(d.find_elements(By.CSS_SELECTOR, "#search-results-table tr")) > 0
    )

    edit_button = WebDriverWait(driver, 10).until(
        EC.element_to_be_clickable((By.XPATH, '//table[@id="search-results-table"]//button[@onclick="getFlashcardData(event)"]'))
    )
    edit_button.click()

    # Wait for modal to be visible
    WebDriverWait(driver, 10).until(
        lambda d: d.find_element(By.ID, "search-modal").get_attribute("hidden") is None
    )

    # Click the storeLink button in the first row
    storelink_button = WebDriverWait(driver, 10).until(
        EC.element_to_be_clickable((By.XPATH, '//table[@id="flashcard-matches-table"]//button[@onclick="storeLink(event)"]'))
    )
    storelink_button.click()

    # Count rows in modal table before clicking storeLink
    def count_modal_rows():
        return len(driver.find_elements(By.CSS_SELECTOR, "#flashcard-question-table tr"))

    rows_before = WebDriverWait(driver, 10).until(lambda d: count_modal_rows())
    print(f"Rows before clicking storeLink: {rows_before}")

    # Click the storeLink button in the first row
    storelink_button = WebDriverWait(driver, 10).until(
        EC.element_to_be_clickable((By.XPATH, '//tr[@id="collapse-flashcard-matches-table-tr-0"]//button[@onclick="storeLink(event)"]'))
    )
    storelink_button.click()
     
    # Count rows again after clicking
    rows_after = count_modal_rows()
    print(f"Rows after clicking storeLink: {rows_after}")
    print(rows_after == rows_before-1)
    # Final assertion or output
    assert rows_after == rows_before-1, "Row count did not change after clicking storeLink."

