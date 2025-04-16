import os
import urllib.parse

import boto3

from pir_pipeline.ingestion.PIRIngestor import PIRIngestor
from pir_pipeline.utils.SQLAlchemyUtils import SQLAlchemyUtils

s3 = boto3.client('s3')
db_config = {
    "user": os.getenv("DB_USER"),
    "password": os.getenv("DB_PASSWORD"),
    "host": os.getenv("DB_HOST"),
    "port": os.getenv("DB_PORT"),
    "database": "pir"
}
sql_utils = SQLAlchemyUtils(**db_config, drivername="postgresql+psycopg")

def lambda_handler(event, context):
    os.environ["IN_AWS_LAMBDA"] = "True"
    bucket = event['Records'][0]['s3']['bucket']['name']
    key = urllib.parse.unquote_plus(event['Records'][0]['s3']['object']['key'], encoding='utf-8')
    try:
        response = s3.get_object(Bucket=bucket, Key=key)
        PIRIngestor(key, sql_utils).ingest()
        return response["ContentType"]
    except Exception as e:
        print(e)
        print('Error getting object {} from bucket {}. Make sure they exist and your bucket is in the same region as this function.'.format(key, bucket))
        raise e