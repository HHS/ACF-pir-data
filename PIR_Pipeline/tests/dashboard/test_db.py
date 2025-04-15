import pytest
from flask import g
from pir_pipeline.dashboard import create_app
from pir_pipeline.dashboard.db import init_app, get_db, close_db

@pytest.mark.usefixtures("create_database", "app")
def test_get_db(app):
    with app.app_context():
        db = get_db()
        assert db is not None
        
def test_close_db(app):
    with app.app_context():
        db = get_db()
        assert db is not None
        close_db()
    assert "db" not in g
    
    
def test_init_app(app):
    init_app(app)
    assert close_db in app.teardown_appcontext_funcs

if __name__ == "__main__":
    pytest.main([__file__, '-sk', ''])