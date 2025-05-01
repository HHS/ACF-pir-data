# Move to pir-ingestor-lambda directory
cd pir-ingestor-lambda

# Get all of the files for which we want to create events
files=($(aws s3api list-objects --bucket pir-data | jq -r '.Contents[].Key'))

# Create events and invoke the lambda function
for i in "${files[@]}"
do
    sam local generate-event s3 put --bucket pir-data --key $i > events/event.json
    sam local invoke --env-vars env/env.json --event events/event.json
done

# Delete the event.json file
rm events/event.json