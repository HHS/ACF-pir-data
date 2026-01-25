import multiprocessing
import os
import time

import pytest
import requests
from selenium import webdriver
from selenium.webdriver.firefox.options import Options
from werkzeug.serving import make_server

from pir_pipeline.config import DB_CONFIG
from pir_pipeline.dashboard import create_app


@pytest.fixture(scope="module")
def app(insert_question_records):
    test_db_config = DB_CONFIG.copy()
    test_config = {
        "TESTING": True,
        "DB_CONFIG": test_db_config,
        "DB_NAME": "pir_test",
        "SECRET_KEY": "dev",
    }
    app = create_app(
        test_config=test_config,
        template_folder=os.path.join(
            os.path.dirname(__file__),
            "..",
            "..",
            "src",
            "pir_pipeline",
            "dashboard",
            "templates",
        ),
    )

    yield app


@pytest.fixture(scope="module")
def client(app):
    return app.test_client()


@pytest.fixture(scope="module")
def runner(app):
    return app.test_cli_runner()


@pytest.fixture
def driver():
    options = Options()
    # options.add_argument("--headless")
    driver = webdriver.Firefox(options=options)

    yield driver
    driver.quit()


# Adapted from Claude 3.5s
def run_app():
    config = {"DB_CONFIG": DB_CONFIG, "DB_NAME": "pir_test", "SECRET_KEY": "dev"}
    app = create_app(test_config=config)
    server = make_server("localhost", 5000, app)
    server.serve_forever()


# Adapted from Claude 3.5s
@pytest.fixture(scope="module")
def server():
    proc = multiprocessing.Process(target=run_app)
    proc.start()

    # Wait for the server to start
    for _ in range(10):
        try:
            requests.get("http://localhost:5000")
            break
        except requests.ConnectionError:
            time.sleep(0.5)
    else:
        raise Exception("Server did not start")

    yield

    # Shutdown the server
    proc.terminate()
    proc.join()
