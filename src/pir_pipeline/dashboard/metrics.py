"""Routes and logic for the home page"""

import json
import os

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
    with open(
        os.path.join(
            os.path.dirname(__file__), "static/data/daily_confirmed_count.json"
        ),
        "r",
    ) as f:
        confirmed = json.load(f)

    confirmed = list(confirmed.items())
    confirmed.reverse()

    return render_template("metrics/progress.html", confirmed=confirmed)
