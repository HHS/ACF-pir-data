# PirIngestor (was template.yaml PIRIngestor)
# Ingests a PIR export when it lands in the data bucket under input/.

resource "aws_lambda_function" "pir_ingestor" {
  function_name                  = "PirIngestor"
  s3_bucket                      = aws_s3_bucket.data.bucket
  s3_key                         = aws_s3_object.code.key
  runtime                        = local.python_ver
  handler                        = "handlers.ingestor.lambda_handler"
  architectures                  = ["x86_64"]
  source_code_hash               = data.archive_file.code.output_base64sha256
  role                           = aws_iam_role.pir_exec.arn
  layers                         = [aws_lambda_layer_version.pir.arn]
  timeout                        = 900
  memory_size                    = 4096
  reserved_concurrent_executions = 1
  depends_on                     = [aws_s3_object.code, aws_iam_role_policy_attachment.pir]

  environment {
    variables = merge(local.lambda_env, {
      DB_SECRET_NAME = data.aws_secretsmanager_secret.pipeline_config.name
    })
  }

  vpc_config {
    subnet_ids         = var.rds_subnet_ids
    security_group_ids = var.rds_security_groups
  }
}

resource "aws_cloudwatch_log_group" "pir_ingestor" {
  provider          = aws.infra
  name              = "/aws/lambda/${aws_lambda_function.pir_ingestor.function_name}"
  retention_in_days = local.log_retention_days
}

# ---- S3 -> Lambda trigger (was the SAM S3 event) ----
# Scoped to input/ so code/ uploads and the ingestor's own processed/
# writes don't trigger it.
resource "aws_lambda_permission" "pir_ingestor_s3" {
  provider      = aws.infra
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.pir_ingestor.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.data.arn
}

resource "aws_s3_bucket_notification" "data" {
  provider = aws.infra
  bucket   = aws_s3_bucket.data.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.pir_ingestor.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "input/"
  }

  depends_on = [aws_lambda_permission.pir_ingestor_s3]
}
