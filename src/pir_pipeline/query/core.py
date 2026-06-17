"""Routes and logic for the home page"""

import numpy as np
import pandas as pd
from flask import Blueprint, request

from pir_pipeline.query import helpers
from pir_pipeline.query.db import get_db

bp = Blueprint("index", __name__, url_prefix="/")


def get_records(data: dict[str, dict]):
    db = get_db()
    records = helpers.get_responses(db, data)

    return records


@bp.route("/query", methods=["POST"])
def query():
    """Return the Home page"""
    response: dict = request.json
    aggregate_by: list[str] = response.pop("aggregate_by")
    records = get_records(response)
    AGG = helpers.AGG_DEFAULTS
    pop_keys = set()

    df = pd.DataFrame.from_records(records).replace("nan", np.nan)

    if not aggregate_by:
        records = df.drop(columns=["question_id", "uid", "uqid"]).to_dict(
            orient="records"
        )
        return records
    else:
        for var in aggregate_by:
            try:
                AGG.pop(var)
            except KeyError:
                continue

        aggregate_by.extend(["uqid", "year"])

    df["answer"] = df["answer"].astype("float64")

    if "grant_number" not in aggregate_by:
        for key in AGG:
            if key.startswith("grant"):
                pop_keys.add(key)

    if (
        not any([var.startswith("program") for var in aggregate_by])
        and "grant_number" not in aggregate_by
        and "agency_id" not in aggregate_by
    ):
        for key in AGG:
            if (
                key.startswith("program")
                or key.startswith("grant")
                or key == "agency_id"
            ):
                pop_keys.add(key)
    elif (
        any([var.startswith("program") for var in aggregate_by])
        and "grant_number" not in aggregate_by
        and "agency_id" not in aggregate_by
    ):
        for key in AGG:
            if (
                key.startswith("program")
                or key.startswith("grant")
                or key == "agency_id"
            ) and key not in aggregate_by:
                pop_keys.add(key)

    for key in pop_keys:
        AGG.pop(key)

    df["uqid"] = df["uqid"].combine_first(df["question_id"])
    df = df.groupby(aggregate_by).agg(**AGG).reset_index().drop(columns=["uqid"])
    records = df.to_dict(orient="records")

    return records
