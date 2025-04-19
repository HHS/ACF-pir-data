import json

from flask import Blueprint, flash, redirect, render_template, request, url_for

from pir_pipeline.dashboard.db import get_db
from pir_pipeline.utils.dashboard_utils import (
    get_matches,
    get_review_question,
    get_search_results,
    search_matches,
)
from pir_pipeline.utils.SQLAlchemyUtils import SQLAlchemyUtils

bp = Blueprint("search", __name__, url_prefix="/search")


def get_flashcard_question(offset: int, db: SQLAlchemyUtils):
    id_column, record = get_review_question(offset, db)
    matches = get_matches({"record": record}, db)
    output = {"question": get_search_results(record[id_column], db, id_column)}

    matches.pop(0)

    output["matches"] = search_matches(matches, "question_id", db)

    return output


@bp.route("/", methods=("GET", "POST"))
def search():
    """Handle rendering/data acquisition for the search page"""

    # Execute a search
    if request.method == "POST":
        db = get_db()
        # Change the columns displayed in the column dropdown
        if request.headers["Content-Type"] == "application/json":
            response = request.get_json()
            assert response["error"], "Invalid response"

            flash("Please enter a search term")
            return redirect(url_for("search.search"))

        # Return search results
        else:
            keyword = request.form["keyword-search"]

            results = get_search_results(keyword, db)

            return json.dumps(results)

    return render_template("search/search.html")


@bp.route("/flashcard", methods=["GET", "POST"])
def flashcard():
    if request.method == "POST":
        return redirect(url_for("review.finalize"))

    return render_template("search/flashcard.html")


@bp.route("/data", methods=["POST"])
def data():
    db = get_db()
    response = request.get_json()
    output = get_flashcard_question(response["question_id"], db)

    return json.dumps(output)
