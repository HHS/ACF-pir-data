# PirLinker (was template.yaml PIRLinker)
# Links questions that have no uqid yet. Runs once a day.

resource "aws_lambda_function" "pir_linker" {
  function_name    = "PirLinker"
  s3_bucket        = aws_s3_bucket.data.bucket
  s3_key           = aws_s3_object.code.key
  runtime          = local.python_ver
  handler          = "handlers.linker.lambda_handler"
  architectures    = ["x86_64"]
  source_code_hash = data.archive_file.code.output_base64sha256
  role             = aws_iam_role.pir_exec.arn
  layers           = [aws_lambda_layer_version.pir.arn]
  timeout          = 300
  memory_size      = 2048
  depends_on       = [aws_s3_object.code, aws_iam_role_policy_attachment.pir]

  environment {
    variables = merge(local.lambda_env, {
      DB_SECRET_NAME = aws_secretsmanager_secret.pipeline_config.name
    })
  }

  vpc_config {
    subnet_ids         = var.rds_subnet_ids
    security_group_ids = var.rds_security_groups
  }
}

resource "aws_cloudwatch_log_group" "pir_linker" {
  provider          = aws.infra
  name              = "/aws/lambda/${aws_lambda_function.pir_linker.function_name}"
  retention_in_days = local.log_retention_days
}

# ---- Schedule ----
# Was LambdaInvokeEvery30Minutes in template.yaml, though the expression
# has always been daily at 00:00 UTC. Renamed to say what it does (and so
# it doesn't collide with the SAM rule if both exist during cutover).
resource "aws_cloudwatch_event_rule" "pir_linker_schedule" {
  provider            = aws.infra
  name                = "${var.project_name}-LinkerDaily"
  schedule_expression = "cron(0 0 * * ? *)"
  state               = "ENABLED"
}

resource "aws_cloudwatch_event_target" "pir_linker" {
  provider  = aws.infra
  rule      = aws_cloudwatch_event_rule.pir_linker_schedule.name
  target_id = "TargetFunction"
  arn       = aws_lambda_function.pir_linker.arn
}

resource "aws_lambda_permission" "pir_linker" {
  provider      = aws.infra
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.pir_linker.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.pir_linker_schedule.arn
}
