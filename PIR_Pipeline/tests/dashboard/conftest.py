import pytest
from pir_pipeline.dashboard import create_app
from pir_pipeline.config import DB_CONFIG

@pytest.fixture
def app(insert_question_records):
    test_db_config = DB_CONFIG.copy()
    test_config = {
        "TESTING": True,
        "DB_CONFIG": test_db_config,
        "DB_NAME": "pir_test"
    }
    app = create_app(test_config=test_config)

    with app.app_context():
        yield app
        
@pytest.fixture()
def client(app):
    return app.test_client()

@pytest.fixture()
def runner(app):
    return app.test_cli_runner()