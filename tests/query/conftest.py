import os

import pytest

from pir_pipeline.config import DB_CONFIG
from pir_pipeline.query import create_app


@pytest.fixture(scope="module")
def app():
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
            "query",
            "templates",
        ),
    )

    yield app


@pytest.fixture(scope="module")
def client(app):
    return app.test_client()
