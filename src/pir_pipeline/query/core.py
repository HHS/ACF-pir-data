"""Routes and logic for the home page"""

import json
import os
import uuid

import boto3
import numpy as np
import pandas as pd
from botocore.config import Config
from botocore.exceptions import ClientError
from flask import Blueprint, request

from pir_pipeline.query import helpers
from pir_pipeline.query.db import get_db
from pir_pipeline.utils.utils import get_logger

LOGGER = get_logger(__name__)

bp = Blueprint("index", __name__, url_prefix="/")


def get_records(data: dict[str, dict]):
    db = get_db()
    records = helpers.get_responses(db, data)

    return records


def write_to_s3(client, records, **kwargs):
    jsonb = json.dumps(records).encode()
    client.put_object(Body=jsonb, **kwargs)


def gen_presigned_url(client, **kwargs):
    try:
        response = client.generate_presigned_url("get_object", **kwargs)
    except ClientError as e:
        LOGGER.error(e)
        raise

    return response


@bp.route("/query", methods=["POST"])
def query():
    """Return the Home page"""

    response: dict = request.json
    aggregate_by: list[str] = response.pop("aggregate_by")
    s3 = boto3.client(
        "s3",
        config=Config(signature_version="s3v4", s3={"addressing_style": "virtual"}),
    )

    LOGGER.info("Acquiring records.")
    records = get_records(response)
    AGG = helpers.AGG_DEFAULTS
    pop_keys = set()
    LOGGER.info("Successfully acquired records.")

    LOGGER.info("Beginning aggregation.")
    df = pd.DataFrame.from_records(records).replace("nan", np.nan)

    if not aggregate_by:
        records = df.drop(columns=["question_id", "uid", "uqid"]).to_dict(
            orient="records"
        )
        LOGGER.info("No aggregation instructions.")
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

        LOGGER.info("Successfuly aggregated records.")
        LOGGER.info("Successfully completed PIR extract query.")

    uu = uuid.uuid1().hex
    write_to_s3(s3, records, Bucket=os.getenv("PIR_EXTRACT_BUCKET"), Key=f"{uu}.json")

    url = gen_presigned_url(
        s3,
        Params={"Bucket": os.getenv("PIR_EXTRACT_BUCKET"), "Key": f"{uu}.json"},
        ExpiresIn=10,
    )

    return url
