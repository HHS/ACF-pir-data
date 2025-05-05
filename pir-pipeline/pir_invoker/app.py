import json
import os
import time

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
        bucket = event["Records"][0]["s3"]["bucket"]["name"]
        prefix = "input"

        bucket_has_objects = True
        while_init_time = time.time()
        processed = []
        iteration = 0

        while bucket_has_objects:
            # Check for objects in the bucket
            list_objects = s3.list_objects(Bucket=bucket, Prefix=prefix)
            try:
                # If objects are present, process them using the ingestor
                objects = list_objects["Contents"]
                for object in objects:
                    if object["Key"] not in processed:
                        ingestor_event = {"Bucket": bucket, "Key": object["Key"]}
                        lmda.invoke(
                            FunctionName="pir-pipeline-PIRIngestor-B8bZy9dFaMaS",
                            InvocationType="Event",
                            Payload=json.dumps(ingestor_event).encode("utf-8"),
                        )
                        processed.append(object["Key"])

                iteration += 1
            except KeyError:
                # If no objects are present, continue to linking or exit
                bucket_has_objects = False

                if iteration == 0:
                    message = "Bucket has no objects"
                    return {"message": message}

            time_elapsed = time.time() - while_init_time
            if not bucket_has_objects:
                records = sql_utils.get_records(
                    select(sql_utils.tables["unlinked"])
                ).to_dict(orient="records")
                PIRLinker(records, sql_utils).link().update_unlinked()
                message = "PIR pipeline run successfully"
            elif time_elapsed > 600:
                raise TimeoutError("While loop ran for more than 10 minutes")

            # Wait 5 seconds between iterations
            time.sleep(5)

        return {"message": message}
    except Exception as e:
        print(e)
        print("PIR Pipeline failed")
        raise e
