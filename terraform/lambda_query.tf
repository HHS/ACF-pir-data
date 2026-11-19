# PirQuery (was query.tf)
# Flask query app behind an API-key-protected API Gateway, restricted to
# the ACF VPN by WAF.

resource "aws_lambda_function" "pir_query" {
  function_name    = "PirQuery"
  s3_bucket        = aws_s3_bucket.data.bucket
  s3_key           = aws_s3_object.code.key
  runtime          = local.python_ver
  handler          = "handlers.query.lambda_handler"
  architectures    = ["x86_64"]
  source_code_hash = data.archive_file.code.output_base64sha256
  role             = aws_iam_role.pir_exec.arn
  layers           = [aws_lambda_layer_version.pir.arn]
  timeout          = 120
  memory_size      = 1024
  depends_on       = [aws_s3_object.code, aws_iam_role_policy_attachment.pir]

  environment {
    variables = merge(local.lambda_env, {
      DB_SECRET_NAME     = data.aws_secretsmanager_secret.query_config.name
      PIR_EXTRACT_BUCKET = aws_s3_bucket.extracts.bucket
    })
  }

  vpc_config {
    subnet_ids         = var.rds_subnet_ids
    security_group_ids = var.rds_security_groups
  }
}

resource "aws_cloudwatch_log_group" "pir_query" {
  provider          = aws.infra
  name              = "/aws/lambda/${aws_lambda_function.pir_query.function_name}"
  retention_in_days = local.log_retention_days
}

# ------------------------------------------------------------------
# API Gateway
# ------------------------------------------------------------------
resource "aws_api_gateway_rest_api" "pir_query" {
  provider = aws.infra
  name     = "pir_query_lambda_gw"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
  body = jsonencode({
    openapi = "3.0.1"
    info = {
      title   = "PirQuery"
      version = "1.0"
    }
  })
}

resource "aws_api_gateway_resource" "query" {
  provider    = aws.infra
  parent_id   = aws_api_gateway_rest_api.pir_query.root_resource_id
  path_part   = "query"
  rest_api_id = aws_api_gateway_rest_api.pir_query.id
}

resource "aws_api_gateway_method" "query" {
  provider         = aws.infra
  rest_api_id      = aws_api_gateway_rest_api.pir_query.id
  resource_id      = aws_api_gateway_resource.query.id
  http_method      = "POST"
  authorization    = "NONE"
  api_key_required = true
}

resource "aws_api_gateway_integration" "query" {
  provider                = aws.infra
  http_method             = aws_api_gateway_method.query.http_method
  resource_id             = aws_api_gateway_resource.query.id
  rest_api_id             = aws_api_gateway_rest_api.pir_query.id
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = aws_lambda_function.pir_query.invoke_arn
}

resource "aws_api_gateway_deployment" "pir_query" {
  provider    = aws.infra
  rest_api_id = aws_api_gateway_rest_api.pir_query.id
  triggers = {
    redeployment = sha1(
      jsonencode([
        aws_api_gateway_resource.query.id,
        aws_api_gateway_method.query.id,
        aws_api_gateway_integration.query.id
      ])
    )
  }
  depends_on = [
    aws_api_gateway_method.query,
    aws_api_gateway_integration.query,
  ]
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "pir_query" {
  provider      = aws.infra
  rest_api_id   = aws_api_gateway_rest_api.pir_query.id
  stage_name    = "pir_query_lambda_stage"
  deployment_id = aws_api_gateway_deployment.pir_query.id
}

resource "aws_cloudwatch_log_group" "pir_query_api_gw" {
  provider          = aws.infra
  name              = "/aws/api_gw/${aws_api_gateway_rest_api.pir_query.name}"
  retention_in_days = local.log_retention_days
}

resource "aws_lambda_permission" "pir_query_api_gw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.pir_query.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.pir_query.execution_arn}/*/*"
}

# ---- API keys + usage plan ----
resource "aws_api_gateway_usage_plan" "pir_query" {
  provider = aws.infra
  name     = "pir-query-usage-plan"

  api_stages {
    api_id = aws_api_gateway_rest_api.pir_query.id
    stage  = aws_api_gateway_stage.pir_query.stage_name
  }

  throttle_settings {
    rate_limit  = 10
    burst_limit = 20
  }
}

resource "aws_api_gateway_api_key" "pir_query" {
  for_each = var.pir_query_api_consumers
  provider = aws.infra

  name        = "pir-query-${each.key}"
  description = each.value.description
}

resource "aws_api_gateway_usage_plan_key" "pir_query" {
  for_each = var.pir_query_api_consumers
  provider = aws.infra

  key_id        = aws_api_gateway_api_key.pir_query[each.key].id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.pir_query.id
}

# ------------------------------------------------------------------
# WAF: block anything not from the ACF VPN
# ------------------------------------------------------------------
resource "aws_wafv2_ip_set" "pir_query_allowed" {
  provider           = aws.infra
  name               = "pir-query-allowed-ips"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  addresses          = var.acf_vpn_ips
}

resource "aws_wafv2_web_acl" "pir_query" {
  provider = aws.infra
  name     = "pir-query-acl"
  scope    = "REGIONAL"

  default_action {
    allow {} # allow by default, block unknown IPs via rule below
  }

  rule {
    name     = "block-unknown-ips"
    priority = 1
    action {
      block {}
    }
    statement {
      not_statement {
        statement {
          ip_set_reference_statement {
            arn = aws_wafv2_ip_set.pir_query_allowed.arn
          }
        }
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "BlockUnknownIPs"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "PirQueryAcl"
    sampled_requests_enabled   = true
  }
}

resource "aws_wafv2_web_acl_association" "pir_query" {
  provider     = aws.infra
  resource_arn = aws_api_gateway_stage.pir_query.arn
  web_acl_arn  = aws_wafv2_web_acl.pir_query.arn
}
