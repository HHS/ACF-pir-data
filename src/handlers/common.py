"""Shared helpers for the PIR Lambda handlers"""

import json
import os

import boto3

from pir_pipeline.utils.SQLAlchemyUtils import SQLAlchemyUtils


def get_secret() -> dict:
    """Return the JSON secret named by the DB_SECRET_NAME environment variable

    Each function's DB_SECRET_NAME is set in terraform. The secret is expected
    to have the shape ``{"DB_CONFIG": {"user", "password", "host", "port"},
    "DB_NAME": ...}``.
    """
    client = boto3.client("secretsmanager")
    response = client.get_secret_value(SecretId=os.environ["DB_SECRET_NAME"])

    return json.loads(response["SecretString"])


def get_sql_utils() -> SQLAlchemyUtils:
    """Return a SQLAlchemyUtils object built from the function's secret"""
    secret = get_secret()

    return SQLAlchemyUtils(**secret["DB_CONFIG"], database=secret["DB_NAME"])
