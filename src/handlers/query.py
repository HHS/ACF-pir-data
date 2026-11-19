"""PirQuery: Flask query app served behind API Gateway"""

import awsgi

from handlers.common import get_secret
from pir_pipeline.query import create_app

app = create_app(get_secret())


def lambda_handler(event, context):
    return awsgi.response(app, event, context)
