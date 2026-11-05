"""PirIngestor: ingest a PIR export dropped into the data bucket's input/ prefix"""

from collections import namedtuple

import boto3

from handlers.common import get_sql_utils
from pir_pipeline.ingestion.PIRIngestor import PIRIngestor

sql_utils = get_sql_utils()
s3 = boto3.client("s3")


def lambda_handler(event, context):
    try:
        key = event["Records"][0]["s3"]["object"]["key"]
        bucket = event["Records"][0]["s3"]["bucket"]["name"]
        s3_location = namedtuple("S3Location", "bucket key")
        location = s3_location(bucket, key)
        PIRIngestor(location, sql_utils).ingest()
        original_object = {"Bucket": bucket, "Key": key}
        s3.copy(original_object, bucket, key.replace("input", "processed"))
        s3.delete_object(Bucket=bucket, Key=key)
        return {"message": "Success"}
    except Exception as e:
        print(e)
        raise e
