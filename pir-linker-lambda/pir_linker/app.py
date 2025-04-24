import os

from pir_pipeline.linking.PIRLinker import PIRLinker
from pir_pipeline.utils.SQLAlchemyUtils import SQLAlchemyUtils

try:
    DB_CONFIG = {
        "user": os.getenv("DB_USER"),
        "password": os.getenv("DB_PASSWORD"),
        "host": os.getenv("DB_HOST"),
        "port": os.getenv("DB_PORT"),
        "database": os.getenv("DB_NAME")
    }
    os.environ["IN_AWS_LAMBDA"] = "True"
    sql_utils = SQLAlchemyUtils(**DB_CONFIG)
except Exception as e:
    print(f"Error creating sql_utils object: {e}")
    raise e


def lambda_handler(event, context):   
    try:
        records = sql_utils.get_records("SELECT * FROM unlinked").to_dict(
            orient="records"
        )
        PIRLinker(records, sql_utils).link().update_unlinked()
    except Exception as e:
        print(f"Error linking records: {e}")
        raise e