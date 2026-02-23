"""Routes and logic for the home page"""

from flask import Blueprint, render_template

from pir_pipeline.dashboard.db import get_db
from pir_pipeline.dashboard.utils import administrator

bp = Blueprint("metrics", __name__, url_prefix="/metrics")


@bp.route("/")
@administrator
def index():
    db = get_db()
    df = db.get_records("SELECT * FROM link_history")

    approval_by_user = (
        df.groupby("user")
        .aggregate(percent_approved=("decision", "mean"))
        .reset_index()
        .to_dict(orient="index")
    )

    return render_template("metrics/metrics.html", approval_by_user=approval_by_user)


@bp.route("/progress")
@administrator
def progress():
    db = get_db()
    df = db.get_records("SELECT * FROM link_history")

    df["date"] = df["decision_timestamp"].map(lambda stamp: stamp.date())
    # TODO: Filter to only approved
    approved = (
        df.groupby("date")
        .size()
        .reset_index()
        .rename(columns={0: "approved"})
        .to_dict(orient="index")
    )

    return render_template("metrics/progress.html", approved=approved)
