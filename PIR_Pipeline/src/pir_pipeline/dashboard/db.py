from datetime import datetime

import click
from flask import current_app, g

from pir_pipeline.utils.MySQLUtils import MySQLUtils


def get_db():
    if "db" not in g:
        g.db = MySQLUtils(**current_app.config["DB_CONFIG"]).make_connection(
            current_app.config["DB_NAME"]
        )

    return g.db


def close_db(e=None):
    db = g.pop("db", None)

    if db is not None:
        db.close_connection()


def init_app(app):
    app.teardown_appcontext(close_db)
