import os

import boto3

from pir_pipeline.ingestion.PIRIngestor import PIRIngestor
from pir_pipeline.utils.SQLAlchemyUtils import SQLAlchemyUtils

DB_CONFIG = {
    "user": os.getenv("DB_USER"),
    "password": os.getenv("DB_PASSWORD"),
    "host": os.getenv("DB_HOST"),
    "port": os.getenv("DB_PORT"),
    "database": os.getenv("DB_NAME")
}
os.environ["IN_AWS_LAMBDA"] = "True"

sql_utils = SQLAlchemyUtils(**DB_CONFIG)

s3 = boto3.client("s3")


def lambda_handler(event, context):
    try:
        key = event["Key"]
        bucket = event["Bucket"]
        print(event)
        PIRIngestor(key, sql_utils).ingest()
        s3.copy(event, bucket, key.replace("input", "processed"))
        return {"message": "Success"}
    except Exception as e:
        print(e)
        print('Error getting object {} from bucket {}. Make sure they exist and your bucket is in the same region as this function.'.format(key, bucket))
        raise e