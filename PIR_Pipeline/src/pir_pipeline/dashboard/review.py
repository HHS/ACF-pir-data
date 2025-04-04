import json
from hashlib import md5

from flask import Blueprint, render_template, request, session

from pir_pipeline.dashboard.db import get_db
from pir_pipeline.utils.dashboard_utils import (
    QuestionLinker,
    get_matches,
    get_review_data,
)
from pir_pipeline.utils.utils import clean_name

bp = Blueprint("review", __name__, url_prefix="/review")


@bp.route("/")
def index():
    return render_template("review/index.html")


@bp.route("/flashcard")
def flashcard():
    db = get_db()

    # Parse url string
    review_type = request.args.get("review_type")

    # Get data for review
    data = get_review_data(review_type, db)
    columns = data.pop(0)
    columns = [clean_name(col, "title") for col in columns]
    record = data[0]
    session["review_list"] = data

    # Get matches for the first record
    matches = get_matches({"review-type": review_type, "record": record}, db)

    return render_template(
        "review/flashcard.html", columns=columns, record=record, matches=matches
    )


@bp.route("/data", methods=["POST"])
def data():
    db = get_db()
    response = request.get_json()

    if response["for"] == "flashcard":
        review_type = response["review-type"]
        data = get_review_data(review_type, db)
        current = data[0:2]
        record = current[1]

        # Get matches for the first record
        matches = get_matches({"review-type": review_type, "record": record}, db)

        output = {"question": current, "matches": matches}

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
