import json

import awsgi
import boto3
from botocore.exceptions import ClientError

from pir_pipeline.query import create_app


def get_secret():

    secret_name = "pir/query/config"
    region_name = "us-east-1"

    # Create a Secrets Manager client
    session = boto3.session.Session()
    client = session.client(service_name="secretsmanager", region_name=region_name)

    try:
        get_secret_value_response = client.get_secret_value(SecretId=secret_name)
    except ClientError as e:
        # For a list of exceptions thrown, see
        # https://docs.aws.amazon.com/secretsmanager/latest/apireference/API_GetSecretValue.html
        raise e

    secret = get_secret_value_response["SecretString"]
    secret = json.loads(secret)

    return secret


app = create_app(get_secret())


def lambda_handler(event, context):
    return awsgi.response(app, event, context)
