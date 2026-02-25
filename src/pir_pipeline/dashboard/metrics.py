"""Routes and logic for the metrics page"""

from datetime import datetime, timedelta

import pandas as pd
from flask import Blueprint, render_template
from sqlalchemy import func, select

from pir_pipeline.dashboard.db import get_db
from pir_pipeline.dashboard.utils import administrator

bp = Blueprint("metrics", __name__, url_prefix="/metrics")


def get_confirmed_dict(by: list[str] = []):
    db = get_db()

    uqid_changelog = db.tables["uqid_changelog"]
    confirmed = db.tables["confirmed"]

    # Confirmed uqids
    uqids = (
        select(
            uqid_changelog.c["original_uqid"],
            func.min(uqid_changelog.c["timestamp"]).label("timestamp"),
        )
        .group_by(uqid_changelog.c["original_uqid"])
        .having(func.max(uqid_changelog.c["complete_series_flag"]) == 1)
        .subquery()
    )

    # Number of confirmed questions
    confirmed = select(confirmed, uqids.c["timestamp"]).join(
        uqids,
        onclause=uqids.c["original_uqid"] == confirmed.c["uqid"],
    )
    confirmed_df = db.get_records(confirmed)
    confirmed_df["date"] = confirmed_df["timestamp"].map(
        lambda date: date.date().strftime("%Y-%m-%d")
    )
    confirmed_dict = (
        confirmed_df.groupby(by=["date"] + by)
        .size()
        .sort_index(ascending=False)
        .to_dict()
    )

    return confirmed_dict


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


@bp.route("/daily_links")
@administrator
def daily_links():
    confirmed_dict = get_confirmed_dict()

    return render_template("metrics/daily_links.html", confirmed_dict=confirmed_dict)


@bp.route("/projections")
@administrator
def projections():
    def get_projections(
        average: int | pd.DataFrame, remaining_days: int, remaining: int | pd.DataFrame
    ):
        if isinstance(average, pd.DataFrame):
            merged = average.join(remaining)
            merged["year_end"] = merged["average"].map(
                lambda x: round(x * remaining_days)
            )
            merged["difference"] = merged["count"] - merged["year_end"]
            merged["shortfall"] = merged["difference"].map(lambda x: x if x > 0 else 0)
            merged["average"] = merged["average"].round(1)
            out_dict = (
                merged.reset_index()[["year", "average", "year_end", "shortfall"]]
                .sort_values("year", ascending=False)
                .to_dict(orient="index")
            )
        else:
            projection = round(average * remaining_days)
            difference = remaining - projection
            shortfall = difference if difference > 0 else 0

            out_dict = {
                "average": round(average, 1),
                "remaining_days": remaining_days,
                "year_end": projection,
                "shortfall": shortfall,
            }

        return out_dict

    db = get_db()
    confirmed_dict = get_confirmed_dict()
    confirmed_df = pd.DataFrame.from_dict(
        confirmed_dict, orient="index", columns=["count"]
    ).reset_index(names=["date"])

    confirmed_df["date"] = confirmed_df["date"].map(datetime.fromisoformat)
    unconfirmed = db.tables["unconfirmed"]

    remaining_days = (datetime.fromisoformat("2026-10-01") - datetime.today()).days
    remaining_questions = db.get_scalar(
        select(func.count(unconfirmed.table_valued())), {}
    )
    remaining_questions_by_year = db.get_records(
        select(
            func.count(unconfirmed.c["question_id"]), unconfirmed.c["year"]
        ).group_by(unconfirmed.c["year"])
    ).set_index("year")

    # Full data set projections
    weekly_average = (
        confirmed_df[
            confirmed_df["date"].map(
                lambda date: date >= datetime.today() - timedelta(days=7)
            )
        ]["count"].sum()
        / 7
    )
    overall_average = (
        confirmed_df["count"].sum()
        / (datetime.today() - confirmed_df["date"].min()).days
    )

    overall_projection = {
        "Weekly": get_projections(weekly_average, remaining_days, remaining_questions),
        "Overall": get_projections(
            overall_average, remaining_days, remaining_questions
        ),
    }

    # Projections by year
    confirmed_dict = get_confirmed_dict(["year"])
    confirmed_df = pd.DataFrame.from_dict(
        confirmed_dict, orient="index", columns=["count"]
    ).reset_index(names=["date", "year"])

    confirmed_df["date"], confirmed_df["year"] = zip(
        *confirmed_df["date"].map(lambda x: (x[0], x[1]))
    )
    confirmed_df["date"] = confirmed_df["date"].map(datetime.fromisoformat)

    weekly_df = confirmed_df[
        confirmed_df["date"].map(
            lambda date: date >= datetime.today() - timedelta(days=7)
        )
    ]
    weekly_average_df = (
        (weekly_df.groupby("year")["count"].sum() / 7)
        .reset_index()
        .rename(columns={"count": "average"})
        .set_index("year")
    )

    overall_average_df = (
        (
            confirmed_df.groupby("year")["count"].sum()
            / (datetime.today() - confirmed_df["date"].min()).days
        )
        .reset_index()
        .rename(columns={"count": "average"})
        .set_index("year")
    )

    weekly_projections_by_year = get_projections(
        weekly_average_df, remaining_days, remaining_questions_by_year
    )
    overall_projections_by_year = get_projections(
        overall_average_df, remaining_days, remaining_questions_by_year
    )

    return render_template(
        "metrics/projections.html",
        overall_projection=overall_projection,
        weekly_by_year=weekly_projections_by_year,
        overall_by_year=overall_projections_by_year,
    )
