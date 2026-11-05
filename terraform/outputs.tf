output "ingestor_function_name" {
  description = "Name of the PIR ingestion Lambda function."
  value       = aws_lambda_function.pir_ingestor.function_name
}

output "linker_function_name" {
  description = "Name of the PIR linking Lambda function."
  value       = aws_lambda_function.pir_linker.function_name
}

output "query_function_name" {
  description = "Name of the PIR query Lambda function."
  value       = aws_lambda_function.pir_query.function_name
}

output "data_bucket" {
  description = "PIR data bucket. Upload exports to input/ to trigger ingestion."
  value       = aws_s3_bucket.data.bucket
}

output "extract_bucket" {
  description = "Bucket PirQuery writes extracts to."
  value       = aws_s3_bucket.extracts.bucket
}

output "query_url" {
  description = "PirQuery endpoint (POST, requires an API key)."
  value       = "${aws_api_gateway_stage.pir_query.invoke_url}/${aws_api_gateway_resource.query.path_part}"
}
