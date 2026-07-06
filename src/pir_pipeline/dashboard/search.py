"""Routes and logic for the search page"""

import json

from flask import Blueprint, flash, redirect, render_template, request, url_for
from sqlalchemy import select

from pir_pipeline.dashboard.db import get_db
from pir_pipeline.utils.dashboard_utils import (
    all_years,
    confirmed,
    get_matches,
    get_review_question,
    get_search_results,
    pending,
    search_matches,
)
from pir_pipeline.utils.SQLAlchemyUtils import SQLAlchemyUtils

bp = Blueprint("search", __name__, url_prefix="/search")


def get_flashcard_question(offset: int | str, id_column: str, db: SQLAlchemyUtils):
    """Get data for displaying a flashcard

    Args:
        offset (int | str): The question to return. Integer when returning questions by \
        position, string when returning a specific question by id.
        db (SQLAlchemyUtils): SQLAlchemyUtils object for interacting with the database.
        session (dict): Flask session object.

    Returns:
        dict: Dictionary containing data for header question and matching questions.
    """

    id_column, record = get_review_question("question", offset, id_column, db)
    matches = get_matches({"record": record}, db)
    output = {"question": get_search_results(record[id_column], db, id_column)}

    if matches and len(matches) > 1:
        matches.pop(0)
        output["matches"] = search_matches(matches, db)
    elif matches and len(matches) == 1:
        output["matches"] = {"columns": output["question"]["columns"]}
    else:
        output["matches"] = {"columns": output["question"]["columns"]}

    return output


@bp.route("/", methods=("GET", "POST"))
def search():
    """Handle rendering/data acquisition for the search page"""

    db = get_db()

    # Execute a search
    if request.method == "POST":
        # Change the columns displayed in the column dropdown
        if request.headers["Content-Type"] == "application/json":
            response = request.get_json()
            assert response["error"], "Invalid response"

            flash("Please enter a search term")
            return redirect(url_for("search.search"))

        # Return search results
        else:
            keyword = request.form["keyword-search"]
            years = request.form["year-filter"]
            pending_filter = request.form.get("pending-filter")
            if years:
                years = years.strip().strip(",")
                years = [int(year) for year in years.split(",")]

            results = get_search_results(keyword, db, years=years)
            results.update({"keyword": keyword})
            pending_qids = pending(db)
            if not pending_filter:
                drop_due_to_pending = []
                for key, value in results.items():
                    if isinstance(value, list) and isinstance(value[0], dict):
                        if any([v["question_id"] in pending_qids for v in value]):
                            drop_due_to_pending.append(key)

                for key in drop_due_to_pending:
                    results.pop(key)

            results.update(
                {
                    "proposed": pending_qids,
                    "confirmed": confirmed(db),
                    "all_years": all_years(db),
                }
            )

            return json.dumps(results)

    year_df = db.get_records(select(db.tables["question"].c["year"]).distinct())
    years = year_df["year"].tolist()

    return render_template("search/search.html", years=years)


@bp.route("/data", methods=["POST"])
def data():
    """Get data for rendering a flashcard"""

    db = get_db()
    response = request.get_json()
    id_column = "uqid" if response["uqid"] else "question_id"
    output = get_flashcard_question(response[id_column], id_column, db)
    output.get("question").update(
        {
            "proposed": pending(db),
            "confirmed": confirmed(db),
            "all_years": all_years(db),
        }
    )
    output.get("matches").update(
        {
            "proposed": pending(db),
            "confirmed": confirmed(db),
            "all_years": all_years(db),
        }
    )

    return json.dumps(output)
