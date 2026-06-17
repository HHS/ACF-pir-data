import awsgi

from pir_pipeline.query import create_app

app = create_app()


def lambda_handler(event, context):
    print(event)
    print(context)
    return awsgi.response(app, event, context)
