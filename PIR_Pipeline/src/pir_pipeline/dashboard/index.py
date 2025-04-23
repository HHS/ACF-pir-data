import pandas as pd
from flask import Blueprint, render_template
from sqlalchemy import func, select

from pir_pipeline.dashboard.db import get_db

bp = Blueprint("index", __name__)


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
