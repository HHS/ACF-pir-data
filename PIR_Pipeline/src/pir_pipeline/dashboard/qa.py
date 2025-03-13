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
from sqlalchemy import bindparam, select
from werkzeug.exceptions import abort

from pir_pipeline.dashboard.data import get_review_data
from pir_pipeline.dashboard.db import get_db
from pir_pipeline.utils import clean_name, get_searchable_columns

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
        section_id="tables",
    )


@bp.route("/search", methods=("GET", "POST"))
def search():
    db = get_db()
    if request.method == "POST":
        if request.headers["Content-Type"] == "application/json":
            response = request.get_json()
            table = response["value"]
            columns = db.get_columns(table)
            columns = get_searchable_columns(columns)
            return json.dumps(columns)
        else:
            table = request.form["table-select"]
            column = request.form["column-select"]
            keyword = request.form["keyword-search"]

            table = db.tables[table]
            column = clean_name(
                column
            )  # But why not just have the snake_name as the value for the option?

            query = select(table).where(
                table.c[column].regexp_match(bindparam("keyword"))
            )

            data = []
            data.append([clean_name(col, "title") for col in table.c.keys()])
            with db.engine.connect() as conn:
                result = conn.execute(query, {"keyword": keyword})
                for res in result.all():
                    result_dict = {key: res[i] for i, key in enumerate(table.c.keys())}
                    data.append(result_dict)

            return json.dumps(data)

    tables = db.get_records("SHOW TABLES").iloc[:, 0].tolist()
    tables = [
        table
        for table in tables
        if table.find("program") != -1 or table.find("question") != -1
    ]
    columns = db.get_columns(tables[0])
    columns = get_searchable_columns(columns)

    return render_template(
        "search.html", tables=tables, columns=columns, section_id="search-form-section"
    )


@bp.route("/review", methods=["GET", "POST", "PUT"])
def review():
    db = get_db()
    if request.method == "POST":
        review_type = request.form["review-type"]
        data = get_review_data(review_type, db)

        return json.dumps(data)

    return render_template("review.html", section_id="review-form-section")


@bp.route("/match")
def match():
    db = get_db()
    payload = request.get_json()

    return None
