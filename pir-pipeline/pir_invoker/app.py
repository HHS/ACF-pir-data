import json
import os
import time

import boto3

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
        "database": os.getenv("DB_NAME")
    }
    os.environ["IN_AWS_LAMBDA"] = "True"
    sql_utils = SQLAlchemyUtils(**DB_CONFIG)
except Exception as e:
    print(f"Error creating sql_utils object: {e}")
    raise e

def lambda_handler(event, context):
    try:
        bucket = event['Records'][0]['s3']['bucket']['name']
        prefix = "input"
        list_objects = s3.list_objects(Bucket=bucket, Prefix=prefix)
        objects = list_objects["Contents"]
        
        for object in objects:
            ingestor_event = {"Bucket": bucket, "Key": object["Key"]}
            lmda.invoke(FunctionName="pir-pipeline-PIRIngestor-B8bZy9dFaMaS", InvocationType="Event", Payload=json.dumps(ingestor_event).encode("utf-8"))
            
        # Wait until all objects are processed by Ingestor
        bucket_has_objects = True
        while_init_time = time.time()
        while bucket_has_objects:
            list_objects = s3.list_objects(Bucket=bucket, Prefix=prefix)
            objects = list_objects["Contents"]
            time_elapsed = time.time() - while_init_time
            if len(objects) == 1 and objects[0]["Key"] == f"{bucket}/":
                bucket_has_objects = False
                
                records = sql_utils.get_records("SELECT * FROM unlinked").to_dict(
                    orient="records"
                )
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