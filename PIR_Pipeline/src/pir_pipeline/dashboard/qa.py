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
from sqlalchemy import bindparam, func, select
from werkzeug.exceptions import abort

from pir_pipeline.dashboard.db import get_db
from pir_pipeline.utils import SQLAlchemyUtils, clean_name, get_searchable_columns

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


def get_review_data(review_type: str, db: SQLAlchemyUtils):
    if review_type == "unlinked":
        table = db._tables["unlinked"]
        query = select(table)
    elif review_type == "intermittent":
        table = db._tables["question"]
        year_query = select(func.count(func.distinct(table.c.year))).scalar_subquery()
        uqid_query = (
            select(table.c.uqid)
            .group_by(table.c.uqid)
            .having(func.count(table.c.uqid) < year_query)
            .subquery()
        )
        query = (
            select(
                table.c.uqid,
                table.c.question_name,
                table.c.question_number,
                table.c.question_text,
                table.c.section,
                table.c.question_type,
            )
            .where(table.c.uqid.in_(uqid_query))
            .distinct()
        )
    else:
        table = db._tables["linked"]
        subquery = select(table.c.question_id, table.c.uqid).distinct().subquery()
        right = (
            select(subquery.c.uqid)
            .group_by(subquery.c.uqid)
            .having(func.count(subquery.c.question_id) > 1)
            .subquery()
        )
        query = (
            select(
                table.c.uqid,
                table.c.question_name,
                table.c.question_number,
                table.c.question_text,
                table.c.section,
                table.c.question_type,
            )
            .join(right, table.c.uqid == right.c.uqid)
            .distinct()
        )

    with db.engine.connect() as conn:
        result = conn.execute(query)
        data = db.to_dict(result.all(), query.c.keys())

    columns = [clean_name(col, "title") for col in query.c.keys()]
    data.insert(0, columns)

    return data
