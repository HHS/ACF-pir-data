import json
from collections import OrderedDict
from hashlib import md5

from flask import Blueprint, flash, redirect, render_template, request, session, url_for
from sqlalchemy import func, select

from pir_pipeline.dashboard.db import get_db
from pir_pipeline.utils.dashboard_utils import (
    QuestionLinker,
    get_matches,
    get_review_question,
    get_search_results,
    search_matches,
)
from pir_pipeline.utils.SQLAlchemyUtils import SQLAlchemyUtils

bp = Blueprint("review", __name__, url_prefix="/review")


def get_flashcard_question(
    offset: int | str, db: SQLAlchemyUtils, session: dict
) -> dict:
    """Get data for displaying a flashcard

    Args:
        offset (int | str): The question to return. Integer when returning questions by \
        position, string when returning a specific question by id.
        db (SQLAlchemyUtils): SQLAlchemyUtils object for interacting with the database.
        session (dict): Flask session object.

    Returns:
        dict: Dictionary containing data for header question and matching questions.
    """

    id_column, record = get_review_question("unconfirmed", offset, "uqid", db)

    if not record[id_column]:
        id_column = "question_id"

    output = {"question": get_search_results(record[id_column], db, id_column)}

    matches = get_matches({"record": record}, db)
    if matches:
        matches.pop(0)
        output["matches"] = search_matches(matches, id_column, db)
    else:
        output["matches"] = {}

    session["current_question"] = offset

    return output


@bp.route("/", methods=["GET", "POST"])
def index():
    """Render first flashcard"""
    return render_template("review/flashcard.html")


@bp.route("/finalize", methods=["GET", "POST"])
def finalize():
    """Render the finalization page, for reviewing changes made using the dashboard"""

    # Flash an error if no linking actions were performed
    if not session.get("link_dict"):
        flash("No linking actions performed.")
        return render_template("review/flashcard.html")

    if request.method == "POST":
        form = request.form
        action = form["action"]
        link_dict = session.get("link_dict")

        # Remove a linking action from the dictionary
        if action == "remove":
            finalize_id = form["finalize-id"]

            link_dict.pop(finalize_id)
            if not link_dict.keys():
                del session["link_dict"]

            session["link_dict"] = link_dict

            return render_template("review/finalize.html")
        # Commit all linking actions
        elif action == "commit":
            db = get_db()
            QuestionLinker(link_dict, db).update_links()
            session.pop("link_dict")

            return render_template("review/flashcard.html")

    return render_template("review/finalize.html")


@bp.route("/flashcard", methods=["GET", "POST"])
def flashcard():
    """Handle building flashcard page for reviewing questions chronologically"""

    if request.method == "POST":
        db = get_db()

        form = request.form
        action = form["action"]

        # Render finalize page if user clicks finish
        if action == "finish":
            return redirect(url_for("review.finalize"))

        # Move to the next question
        if action == "next":
            offset = session.get("current_question")

            # Increment offset or loop to beginning
            if offset < session.get("max_questions"):
                offset += 1
            else:
                offset = 0

            output = get_flashcard_question(offset, db, session)

        # Move to the previous question
        elif action == "previous":
            offset = session.get("current_question")

            # Decrement offset or loop to the end
            if offset > 0:
                offset -= 1
            else:
                offset = session.get("max_questions")

            output = get_flashcard_question(offset, db, session)

        return json.dumps(output)

    return render_template("review/flashcard.html")


@bp.route("/data", methods=["POST"])
def data():
    """Return data for rendering pages"""
    db = get_db()
    response = request.get_json()

    if response["for"] == "flashcard":
        offset = 0
        output = get_flashcard_question(offset, db, session)
        id_column = "question_id"

        # Get max questions
        query = select(func.count(func.distinct(db.tables["unconfirmed"].c[id_column])))
        with db.engine.connect() as conn:
            result = conn.execute(query)
            max_questions = result.scalar() - 1

        output.update({"current_question": offset, "max_questions": max_questions})
        session["current_question"] = offset
        session["max_questions"] = max_questions

    return json.dumps(output)


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
        dict_id = data["base_question_id"] + data.get("match_question_id", "")
        dict_id = md5(dict_id.encode("utf-8")).hexdigest()
        if link_dict:
            if (dict_id in link_dict) and (
                link_dict[dict_id]["link_type"] != data["link_type"]
            ):
                del link_dict[dict_id]
            else:
                link_dict[dict_id] = data
        else:
            link_dict = OrderedDict({dict_id: data})
        session["link_dict"] = link_dict
        message = f"Data {data} queued for linking"
        print(session["link_dict"])
    # Execute all linking actions
    elif action == "finalize":
        db = get_db()
        link_dict = session["link_dict"]
        QuestionLinker(link_dict, db).update_links()
        message = "Links Updated!"
        del session["link_dict"]

    return {"message": message}
