"""Routes and logic for the home page"""

from flask import Blueprint, render_template
from sqlalchemy import Integer, cast, func, select

from pir_pipeline.dashboard.db import get_db

bp = Blueprint("index", __name__)


@bp.route("/")
def index():
    """Return the Home page"""

    db = get_db()

    # Count of questions by year
    question = db.tables["question"]
    unconfirmed = db.tables["unconfirmed"]
    confirmed = db.tables["confirmed"]

    confirmed_query = select(confirmed.c.question_id)
    unconfirmed_query = select(unconfirmed.c.question_id)

    questions_by_year = (
        select(
            func.count(question.c.year).label("count"),
            question.c.year,
            func.sum(cast(question.c.question_id.in_(confirmed_query), Integer)).label(
                "confirmed"
            ),
            func.sum(
                cast(question.c.question_id.in_(unconfirmed_query), Integer)
            ).label("unconfirmed"),
        )
        .group_by(question.c.year)
        .order_by(question.c.year.desc())
    )

    years = db.get_records(questions_by_year)
    years = years.to_dict(orient="index")

    with db.engine.connect() as conn:
        result = conn.execute(select(func.count(question.c.question_id)))
        total_questions = result.scalar()

        result = conn.execute(select(func.count(confirmed.c.question_id)))
        confirmed_questions = result.scalar()

    return render_template(
        "index.html",
        years=years,
        section_id="tables",
        total_questions=total_questions,
        confirmed_questions=confirmed_questions,
    )
