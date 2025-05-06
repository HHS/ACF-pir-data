import os

import boto3
from sqlalchemy import select

from pir_pipeline.linking.PIRLinker import PIRLinker
from pir_pipeline.utils.SQLAlchemyUtils import SQLAlchemyUtils

s3 = boto3.client("s3")
lmda = boto3.client("lambda")

try:
    DB_CONFIG = {
        "user": os.getenv("DB_USER"),
        "password": os.getenv("DB_PASSWORD"),
        "host": os.getenv("DB_HOST"),
        "port": os.getenv("DB_PORT"),
        "database": os.getenv("DB_NAME"),
    }
    os.environ["IN_AWS_LAMBDA"] = "True"
    sql_utils = SQLAlchemyUtils(**DB_CONFIG)
except Exception as e:
    print(f"Error creating sql_utils object: {e}")
    raise e


def lambda_handler(event, context):
    try:
        records = sql_utils.get_records(select(sql_utils.tables["unlinked"])).to_dict(
            orient="records"
        )
        PIRLinker(records, sql_utils).link().update_unlinked()
        message = "Records linked successfully."

        return {"message": message}
    except Exception as e:
        print(e)
        print("Failed to link records")
        raise e
