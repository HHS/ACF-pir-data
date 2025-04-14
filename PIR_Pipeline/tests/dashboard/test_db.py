import os
import tempfile
import re
import pytest
from flask import g, Flask
from pir_pipeline.dashboard import create_app
from pir_pipeline.dashboard.db import init_app, get_db, close_db

@pytest.mark.usefixtures("app", "create_database")
def test_get_db(app):
    with app.app_context():
        db = get_db()
        assert db is not None
        
@pytest.mark.usefixtures("app", "create_database")
def test_close_db(app):
    with app.app_context():
        db = get_db()
        assert db is not None
        close_db()
    assert "db" not in g
    
    
@pytest.mark.usefixtures("app", "create_database")
def test_init_app():
    app = Flask(__name__)
    init_app(app)
    
    # Check if close_db is registered as a teardown function
    assert close_db in app.teardown_appcontext_funcs

if __name__ == "__main__":
    pytest.main([__file__, '-sk', ''])