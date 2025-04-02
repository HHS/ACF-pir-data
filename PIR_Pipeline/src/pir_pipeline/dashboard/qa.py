import functools
import hashlib
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
from sqlalchemy import func, select
from werkzeug.exceptions import abort

from pir_pipeline.dashboard.db import get_db
from pir_pipeline.utils.dashboard_utils import (
    QuestionLinker,
    get_matches,
    get_review_data,
    get_search_results,
)
from pir_pipeline.utils.utils import get_searchable_columns

bp = Blueprint("qa", __name__)


@bp.route("/")
def index():
    """Return the Home page"""
    db = get_db()
    linked = db.tables["linked"]
    unlinked = db.tables["unlinked"]

    # Total questions
    total_linked_questions = select(
        func.count(linked.c.question_id).label("total_questions")
    )
    total_unlinked_questions = select(
        func.count(unlinked.c.question_id).label("total_questions")
    )
    total_questions = pd.concat(
        [
            db.get_records(total_linked_questions),
            db.get_records(total_unlinked_questions),
        ]
    )
    total_questions.index = ["Linked", "Unlinked"]
    total_questions = total_questions.to_dict(orient="index")

    # Unique questions
    unique_linked_questions = select(
        func.count(func.distinct(linked.c.question_id)).label("unique_questions")
    )
    unique_unlinked_questions = select(
        func.count(func.distinct(unlinked.c.question_id)).label("unique_questions")
    )
    unique_questions = pd.concat(
        [
            db.get_records(unique_linked_questions),
            db.get_records(unique_unlinked_questions),
        ]
    )
    unique_questions.index = ["Linked", "Unlinked"]
    unique_questions = unique_questions.to_dict(orient="index")

    # Count of questions by year
    question = db.tables["question"]
    questions_by_year = (
        select(func.count(question.c.year).label("count"), question.c.year)
        .group_by(question.c.year)
        .order_by(question.c.year)
    )
    years = db.get_records(questions_by_year)
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
    """Handle rendering/data acquisition for the search page"""
    db = get_db()

    # Execute a search
    if request.method == "POST":
        # Change the columns displayed in the column dropdown
        if request.headers["Content-Type"] == "application/json":
            response = request.get_json()
            if response["error"]:
                flash("Please enter a search term")
                return redirect(url_for("qa.search"))

            table = response["value"]
            columns = db.get_columns(table)
            columns = get_searchable_columns(columns)

            return json.dumps(columns)
        # Return search results
        else:
            table = request.form["table-select"]
            column = request.form["column-select"]
            keyword = request.form["keyword-search"]

            results = get_search_results(column, table, keyword, db)

            return json.dumps(results)

    # Return the default search layout
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


@bp.route("/review", methods=["GET", "POST"])
def review():
    """Handle rendering/data acquisition for the review page"""
    db = get_db()

    # Return results for the specified review type
    if request.method == "POST":
        review_type = request.form["review-type"]
        data = get_review_data(review_type, db)

        return json.dumps(data)

    # Return the base review page
    return render_template("review.html", section_id="review-form-section")


@bp.route("/match", methods=["POST"])
def match():
    """Get matching questions for the target question"""
    db = get_db()
    payload = request.get_json()
    matches = get_matches(payload, db)

    return json.dumps(matches)


@bp.route("/link", methods=["POST"])
def link():
    """Handle storage of link/unlink actions"""
    payload = request.get_json()
    action = payload["action"]
    data = payload["data"]

    # Add a link/unlink entry to session
    if action == "build":
        link_dict = session.get("link_dict")
        dict_id = hashlib.md5(str(data).encode("utf-8")).hexdigest()
        if link_dict:
            # May need to handle user selecting the same link twice, may not
            # if dict_id in link_dict:
            #     flash()
            link_dict[dict_id] = data
        else:
            link_dict = {dict_id: data}
        session["link_dict"] = link_dict
        message = f"Data {data} queued for linking"
    # Return all links/unlinks made in this session
    elif action == "check":
        return session["link_dict"] or {}
    # Execute all linking actions
    elif action == "confirm":
        db = get_db()
        link_dict = session["link_dict"]
        QuestionLinker(link_dict, db).update_links()
        message = "Links Updated!"
        del session["link_dict"]
    # Remove the linking action from the link_dict
    elif action == "remove":
        session["link_dict"].pop(data)
        message = f"Question {data} removed from list of links."

    return {"message": message}
