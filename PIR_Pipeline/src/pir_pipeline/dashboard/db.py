from datetime import datetime

import click
from flask import current_app, g

from pir_pipeline.utils import SQLAlchemyUtils


def get_db():
    if "db" not in g:
        g.db = SQLAlchemyUtils(
            **current_app.config["DB_CONFIG"], database=current_app.config["DB_NAME"]
        )

    return g.db


# Need to revisit
def close_db(e=None):
    db = g.pop("db", None)

    if db is not None:
        db.close_connection()


# Need to revisit
def init_app(app):
    app.teardown_appcontext(close_db)
