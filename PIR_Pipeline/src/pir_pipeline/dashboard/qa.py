import functools
import json

import pandas as pd
from flask import (
    Blueprint,
    flash,
    g,
    redirect,
    render_template,
    request,
    session,
    url_for,
)
from werkzeug.exceptions import abort

from pir_pipeline.dashboard.db import get_db
from pir_pipeline.utils.utils import get_searchable_columns

bp = Blueprint("qa", __name__)


@bp.route("/")
def index():
    db = get_db()
    total_questions = pd.concat(
        [
            db.get_records("SELECT COUNT(question_id) AS total_questions FROM linked"),
            db.get_records(
                "SELECT COUNT(question_id) AS total_questions  FROM unlinked"
            ),
        ]
    )
    total_questions.index = ["Linked", "Unlinked"]
    total_questions = total_questions.to_dict(orient="index")
    unique_questions = pd.concat(
        [
            db.get_records(
                "SELECT COUNT(DISTINCT question_id) AS unique_questions FROM linked"
            ),
            db.get_records(
                "SELECT COUNT(DISTINCT question_id) AS unique_questions FROM unlinked"
            ),
        ]
    )
    unique_questions.index = ["Linked", "Unlinked"]
    unique_questions = unique_questions.to_dict(orient="index")

    years = db.get_records(
        "SELECT COUNT(`year`) AS count, `year` FROM question GROUP BY `year` ORDER BY `year`"
    )
    years = years.to_dict(orient="index")

    return render_template(
        "index.html",
        total_questions=total_questions,
        unique_questions=unique_questions,
        years=years,
    )


@bp.route("/search", methods=("GET", "POST"))
def search():
    db = get_db()
    if request.method == "POST":
        response = request.get_json()
        table = response["value"]
        if response["element"] == "table-select":
            columns = db.get_columns(table)
            columns = get_searchable_columns(columns)

        return json.dumps(columns)

    tables = db.get_records("SHOW TABLES").iloc[:, 0].tolist()
    tables = [
        table
        for table in tables
        if table.find("program") != -1 or table.find("question") != -1
    ]
    columns = db.get_columns(tables[0])
    columns = get_searchable_columns(columns)

    return render_template("search.html", tables=tables, columns=columns)


@bp.route("/review")
def review():
    pass
