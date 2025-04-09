import json
from collections import OrderedDict
from hashlib import md5

from flask import Blueprint, flash, redirect, render_template, request, session, url_for
from sqlalchemy import func, select

from pir_pipeline.dashboard.db import get_db
from pir_pipeline.utils.dashboard_utils import (
    QuestionLinker,
    get_matches,
    get_review_data,
    get_review_question,
    get_search_results,
    search_matches,
)
from pir_pipeline.utils.SQLAlchemyUtils import SQLAlchemyUtils

bp = Blueprint("review", __name__, url_prefix="/review")


def get_flashcard_question(
    review_type: str, offset: int, db: SQLAlchemyUtils, session: dict
):
    id_column, record = get_review_question(review_type, offset, db)
    matches = get_matches({"review-type": review_type, "record": record}, db)
    output = {
        "question": get_search_results(
            review_type, id_column, record[id_column], db, id_column
        )
    }
    matches.pop(0)
    if review_type == "inconsistent":
        output["matches"] = search_matches(matches, "question_id", db)
    else:
        output["matches"] = search_matches(matches, id_column, db)
    session["current_question"] = offset
    return output


@bp.route("/", methods=["GET", "POST"])
def index():
    if request.method == "POST":
        return redirect(url_for("review.finalize"))

    return render_template("review/index.html")


@bp.route("/finalize", methods=["GET", "POST"])
def finalize():
    if not session.get("link_dict"):
        flash("No linking actions performed.")
        return render_template("review/index.html")

    if request.method == "POST":
        form = request.form
        action = form["action"]
        link_dict = session.get("link_dict")

        if action == "remove":
            finalize_id = form["finalize-id"]

            link_dict.pop(finalize_id)
            if not link_dict.keys():
                del session["link_dict"]

            session["link_dict"] = link_dict

            return render_template("review/finalize.html")
        elif action == "commit":
            db = get_db()
            QuestionLinker(link_dict, db).update_links()
            session.pop("link_dict")

            return render_template("review/index.html")

    return render_template("review/finalize.html")


@bp.route("/flashcard", methods=["GET", "POST"])
def flashcard():
    if request.method == "POST":
        db = get_db()

        form = request.form
        action = form["action"]
        review_type = form["review-type"]

        if action == "next":
            offset = session.get("current_question")

            # Increment offset or loop to beginning
            if offset < session.get("max_questions"):
                offset += 1
            else:
                offset = 0

            output = get_flashcard_question(review_type, offset, db, session)
        elif action == "previous":
            offset = session.get("current_question")

            if offset > 0:
                offset -= 1
            else:
                offset = session.get("max_questions")

            output = get_flashcard_question(review_type, offset, db, session)
        elif action == "confirm":
            pass

        return json.dumps(output)

    return render_template("review/flashcard.html")


@bp.route("/data", methods=["POST"])
def data():
    db = get_db()
    response = request.get_json()

    if response["for"] == "flashcard":
        review_type = response["review-type"]
        offset = 0
        output = get_flashcard_question(review_type, offset, db, session)
        id_column = "question_id" if review_type == "unlinked" else "uqid"

        # Get max questions
        query = select(func.count(func.distinct(db.tables[review_type].c[id_column])))
        with db.engine.connect() as conn:
            result = conn.execute(query)
            max_questions = result.scalar() - 1

        output.update({"current_question": offset, "max_questions": max_questions})
        session["current_question"] = offset
        session["max_questions"] = max_questions

    return json.dumps(output)


@bp.route("/table", methods=["GET", "POST"])
def table():
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
        dict_id = md5(str(data).encode("utf-8")).hexdigest()
        if link_dict:
            # May need to handle user selecting the same link twice, may not
            # if dict_id in link_dict:
            #     flash()
            link_dict[dict_id] = data
        else:
            link_dict = OrderedDict({dict_id: data})
        session["link_dict"] = link_dict
        message = f"Data {data} queued for linking"
    # Execute all linking actions
    elif action == "finalize":
        db = get_db()
        link_dict = session["link_dict"]
        QuestionLinker(link_dict, db).update_links()
        message = "Links Updated!"
        del session["link_dict"]

    return {"message": message}
