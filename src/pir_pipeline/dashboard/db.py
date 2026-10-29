"""Manage database connections"""

from flask import current_app, g

from pir_pipeline.utils.SQLAlchemyUtils import SQLAlchemyUtils


def get_db():
    """Return a shared SQLAlchemyUtils object.

    A single ``SQLAlchemyUtils`` (and its pooled engine) is created once per
    application and reused across requests, rather than rebuilt on every
    request. This avoids re-running driver detection and recreating the engine
    each time; SQLAlchemy's engine is thread-safe and manages its own
    connection pool. A reference is also stashed on ``g`` for the current
    request so it can be released on teardown.
    """
    db = current_app.extensions.get("pir_db")
    if db is None:
        db = SQLAlchemyUtils(
            **current_app.config["DB_CONFIG"], database=current_app.config["DB_NAME"]
        )
        current_app.extensions["pir_db"] = db

    g.db = db
    return db


def close_db(e=None):
    """Release the per-request database reference.

    Runs on every app-context teardown but intentionally does NOT dispose the
    shared engine, which is reused across requests. The pooled engine lives for
    the lifetime of the application; use :func:`dispose_db` to tear it down.
    """
    g.pop("db", None)


def dispose_db(app=None):
    """Dispose of the shared SQLAlchemy engine for ``app``.

    Not wired to per-request teardown; call explicitly (e.g. at process
    shutdown or in tests) when the pooled engine should be closed.
    """
    app = app or current_app
    db = app.extensions.pop("pir_db", None)
    if db is not None:
        db.engine.dispose()


def init_app(app):
    """Add close_db to the operations performed when tearing down"""
    app.teardown_appcontext(close_db)
