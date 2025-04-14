import os
import tempfile
import re
import pytest
from flask import g
from pir_pipeline.dashboard import create_app
from pir_pipeline.dashboard.db import get_db, close_db

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
    
if __name__ == "__main__":
    pytest.main([__file__, '-sk', ''])