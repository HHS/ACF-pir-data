import pytest
from flask import g

from pir_pipeline.dashboard.db import close_db, get_db, init_app


@pytest.mark.usefixtures("create_database", "app")
def test_get_db(app):
    """Tests to ensure that a database is returned on get_db()"""
    with app.app_context():
        db = get_db()
        assert db is not None


def test_close_db(app):
    """Tests to ensure that the database is removed from the app context on close_db()"""
    with app.app_context():
        db = get_db()
        assert db is not None
        close_db()
    assert "db" not in g


def test_init_app(app):
    """Tests to ensure that init_app() adds close_db() to the app context."""
    init_app(app)
    assert close_db in app.teardown_appcontext_funcs


if __name__ == "__main__":
    pytest.main([__file__, "-sk", ""])
