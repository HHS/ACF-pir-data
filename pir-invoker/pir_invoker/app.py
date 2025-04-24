import time

import boto3

s3 = boto3.client("s3")
lmda = boto3.client("lambda")

def lambda_handler(event, context):
    try:
        bucket = "pir-data"
        prefix = "input"
        list_objects = s3.list_objects(Bucket=bucket, Prefix=prefix)
        objects = list_objects["Contents"]
        
        for object in objects:
            ingestor_event = {"Bucket": bucket, "Key": object["Key"]}
            lmda.invoke("PIRIngestor", InvocationType="Event", Payload=ingestor_event)
            
        # Wait until all objects are processed by Ingestor
        bucket_has_objects = True
        while_init_time = time.time()
        while bucket_has_objects:
            list_objects = s3.list_objects(Bucket=bucket, Prefix=prefix)
            objects = list_objects["Contents"]
            time_elapsed = time.time() - while_init_time()
            if len(objects) == 1 and objects[0]["Key"] == "input/":
                bucket_has_objects = False
                
                lmda.invoke("PIRLinker", InvocationType="Event")
                message = "PIR pipeline run successfully"
            elif time_elapsed > 600:
                raise RuntimeError("While loop ran for more than 10 minutes")
            
            # Wait 5 seconds between iterations
            time.sleep(5)
        
        return {"message": message}
    except Exception as e:
        print(e)
        print("PIR Pipeline failed")
        raise e