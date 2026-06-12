"""Routes and logic for the home page"""

from flask import Blueprint, request
from sqlalchemy import and_, bindparam, func, select

from pir_pipeline.dashboard.db import get_db

bp = Blueprint("index", __name__, url_prefix="/helpers")


@bp.route("/uqid", methods=["POST"])
def uqid():
    """Return the Home page"""

    db = get_db()
    question_table = db.tables["question"]
    response: list[dict] = request.get_json()

    uqids = []
    for item in response:
        condition = [question_table.c[key] == bindparam(key) for key in item]

        query = select(func.distinct(question_table.c["uqid"])).where(and_(*condition))
        uqid = db.get_scalar(query, item)
        if uqid:
            uqids.append(uqid)

    return list(set(uqids))
