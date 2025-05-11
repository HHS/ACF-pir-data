"""Manage database connections"""

from flask import current_app, g

from pir_pipeline.utils.SQLAlchemyUtils import SQLAlchemyUtils


def get_db():
    """Return a SQLAlchemyUtils object"""
    if "db" not in g:
        g.db = SQLAlchemyUtils(
            **current_app.config["DB_CONFIG"], database=current_app.config["DB_NAME"]
        )

    return g.db


# Need to revisit
def close_db(e=None):
    """Dispose of SQLAlchemy Engine"""
    db = g.pop("db", None)

    if db is not None:
        db.engine.dispose()


# Need to revisit
def init_app(app):
    """Add close_db to the operations performed when tearing down"""
    app.teardown_appcontext(close_db)
