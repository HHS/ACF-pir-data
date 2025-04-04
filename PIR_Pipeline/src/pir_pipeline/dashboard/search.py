import json

from flask import Blueprint, flash, redirect, render_template, request, url_for

from pir_pipeline.dashboard.db import get_db
from pir_pipeline.utils.dashboard_utils import get_search_results
from pir_pipeline.utils.utils import get_searchable_columns

bp = Blueprint("search", __name__)


@bp.route("/search", methods=("GET", "POST"))
def search():
    """Handle rendering/data acquisition for the search page"""
    db = get_db()
    table = "question"

    # Execute a search
    if request.method == "POST":
        # Change the columns displayed in the column dropdown
        if request.headers["Content-Type"] == "application/json":
            response = request.get_json()
            assert response["error"], "Invalid response"

            flash("Please enter a search term")
            return redirect(url_for("qa.search"))

        # Return search results
        else:
            column = request.form["column-select"]
            qtype = request.form["type-select"]
            keyword = request.form["keyword-search"]

            results = get_search_results(qtype, column, keyword, db)

            return json.dumps(results)

    # Return the default search layout
    columns = db.get_columns(table)
    columns = get_searchable_columns(columns)

    return render_template(
        "search.html", columns=columns, section_id="search-form-section"
    )
