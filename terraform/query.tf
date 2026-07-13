# Adapted from Claude

locals {
  layer_name = "pir-pipeline-layer"
  python_ver = "python3.12"
  build_dir  = "${path.module}/.build/layer"
  query_dir  = "${path.module}/.build/query"
  query_zip  = "${path.module}/.build/query.zip"
  zip_path   = "${path.module}/.build/layer.zip"
  # Hash pyproject.toml so the layer rebuilds only when deps change
  deps_hash = filemd5("${path.module}/../src/pir_pipeline/query/requirements.txt")
  code_hash = sha1(join("", [
    for f in sort(fileset("${path.module}/../src/pir_pipeline", "**/*")) :
    filemd5("${path.module}/../src/pir_pipeline/${f}")
  ]))
}

# ------------------------------------------------------------------
# Install dependencies into the Lambda-compatible directory layout
# ------------------------------------------------------------------
resource "null_resource" "build_layer" {
  triggers = {
    deps_hash = local.deps_hash
  }

  provisioner "local-exec" {
    command     = <<-EOT
      set -e
      rm -rf "${local.build_dir}"
      mkdir -p "${local.build_dir}/python"

      # Export only the non-dev dependencies and install them
      pip install \
        --platform manylinux2014_x86_64 \
        --implementation cp \
        --python-version ${replace(local.python_ver, "python", "")} \
        --only-binary=:all: \
        --target "${local.build_dir}/python" \
        --requirement "${path.module}/../src/pir_pipeline/query/requirements.txt"
    EOT
    working_dir = path.module
  }
}

# ------------------------------------------------------------------
# Zip the build output
# ------------------------------------------------------------------
data "archive_file" "layer_zip" {
  depends_on  = [null_resource.build_layer]
  type        = "zip"
  source_dir  = local.build_dir
  output_path = local.zip_path
}

# ------------------------------------------------------------------
# Upload Lambda Layer to S3
# ------------------------------------------------------------------

resource "aws_s3_object" "pir_query_layer" {
  bucket = var.pir_s3_name
  key    = "code/pir-query-layer.zip"
  source = data.archive_file.layer_zip.output_path
  etag   = data.archive_file.layer_zip.output_md5
}

# ------------------------------------------------------------------
# Publish the Lambda layer
# ------------------------------------------------------------------
resource "aws_lambda_layer_version" "this" {
  layer_name          = local.layer_name
  s3_bucket           = var.pir_s3_name
  s3_key              = aws_s3_object.pir_query_layer.key
  compatible_runtimes = [local.python_ver]

  description = "Python dependencies from pyproject.toml (hash: ${local.deps_hash})"
}

# ------------------------------------------------------------------
# Move the Lambda Code
# ------------------------------------------------------------------

resource "null_resource" "move_code" {
  triggers = {
    code_hash = local.code_hash
  }

  provisioner "local-exec" {
    command     = <<-EOT
        rm -rf "${local.query_dir}"
        mkdir -p "${local.query_dir}"
        cp -r "${path.module}/../src/pir_pipeline" "${local.query_dir}/pir_pipeline"
        cp "${path.module}/pir_query.py" "${local.query_dir}/pir_query.py"
    EOT
    working_dir = path.module
  }
}

# ------------------------------------------------------------------
# Zip the Lambda Code
# ------------------------------------------------------------------

data "archive_file" "lambda_pir_query" {
  type        = "zip"
  depends_on  = [null_resource.move_code]
  source_dir  = local.query_dir
  output_path = local.query_zip
}

# ------------------------------------------------------------------
# Upload Lambda Code to S3
# ------------------------------------------------------------------

resource "aws_s3_object" "pir_query_code" {
  bucket = var.pir_s3_name
  key    = "code/pir-query.zip"
  source = data.archive_file.lambda_pir_query.output_path
  etag   = data.archive_file.lambda_pir_query.output_md5
}

# ------------------------------------------------------------------
# Create Lambda Function
# ------------------------------------------------------------------

resource "aws_lambda_function" "pir_query" {
  function_name    = "PirQuery"
  s3_bucket        = var.pir_s3_name
  s3_key           = "code/pir-query.zip"
  runtime          = "python3.12"
  handler          = "pir_query.lambda_handler"
  source_code_hash = data.archive_file.lambda_pir_query.output_base64sha256
  role             = aws_iam_role.lambda_exec.arn
  layers           = [aws_lambda_layer_version.this.arn]
  depends_on       = [aws_s3_object.pir_query_code]
  timeout          = 120
  memory_size      = 1024
  environment {
    variables = {
      IN_AWS_LAMBDA = "True"
      PIR_EXTRACT_BUCKET = aws_s3_bucket.extracts.bucket
    }
  }
  vpc_config {
    subnet_ids         = var.rds_subnet_ids
    security_group_ids = var.rds_security_groups
  }
}

resource "aws_cloudwatch_log_group" "pir_query" {
  provider          = aws.infra
  name              = "/aws/lambda/${aws_lambda_function.pir_query.function_name}"
  retention_in_days = 7
}

resource "aws_iam_role" "lambda_exec" {
  name = "serverless_lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid    = ""
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

data "aws_iam_policy_document" "pir_rds_policy" {
  statement {
    actions   = ["rds:DescribeDBInstances", "rds:Connect", "rds:ExecuteStatement"]
    effect    = "Allow"
    resources = [var.pir_rds_arn]
  }
}

resource "aws_iam_policy" "pir_rds_policy" {
  name   = "pir-rds-policy"
  policy = data.aws_iam_policy_document.pir_rds_policy.json
}

data "aws_iam_policy_document" "pir_s3_policy" {
  statement {
    actions   = ["s3:ListBucket", "s3:ListObjects"]
    effect    = "Allow"
    resources = [var.pir_s3_arn, aws_s3_bucket.extracts.arn]
  }
  statement {
    actions   = ["s3:GetObject", "s3:PutObject", "s3:CopyObject", "s3:DeleteObject"]
    effect    = "Allow"
    resources = ["${var.pir_s3_arn}/*", "${aws_s3_bucket.extracts.arn}/*"]
  }
  depends_on = [aws_s3_bucket.extracts]
}

resource "aws_iam_policy" "pir_s3_policy" {
  name   = "pir-s3-policy"
  policy = data.aws_iam_policy_document.pir_s3_policy.json
}

data "aws_iam_policy_document" "pir_ec2_policy" {
  statement {
    actions   = ["ec2:CreateNetworkInterface", "ec2:DescribeNetworkInterfaces", "ec2:DeleteNetworkInterface", "ec2:DescribeSubnets", "ec2:DescribeSecurityGroups", "ec2:DescribeVpcs", "ec2:AttachNetworkInterface"]
    effect    = "Allow"
    resources = ["*"]
  }
}

resource "aws_iam_policy" "pir_ec2_policy" {
  name   = "pir-ec2-policy"
  policy = data.aws_iam_policy_document.pir_ec2_policy.json
}

data "aws_iam_policy_document" "pir_secrets_policy" {
  statement {
    actions   = ["secretsmanager:GetSecretValue"]
    effect    = "Allow"
    resources = ["arn:aws:secretsmanager:us-east-1:${var.account_id}:secret:pir/query/config*"]
  }
  statement {
    actions   = ["kms:Decrypt"]
    effect    = "Allow"
    resources = ["arn:aws:kms:us-east-1:${var.account_id}:key/*"]
  }
}

resource "aws_iam_policy" "pir_secrets_policy" {
  name   = "pir-secrets-policy"
  policy = data.aws_iam_policy_document.pir_secrets_policy.json
}


resource "aws_iam_role_policy_attachment" "lambda_policy" {
  for_each   = tomap({ "lambda" = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole", "rds" = aws_iam_policy.pir_rds_policy.arn, "s3" = aws_iam_policy.pir_s3_policy.arn, "ec2" = aws_iam_policy.pir_ec2_policy.arn, "secrets" = aws_iam_policy.pir_secrets_policy.arn })
  role       = aws_iam_role.lambda_exec.name
  policy_arn = each.value
}

# ------------------------------------------------------------------
# Create API Gateway
# ------------------------------------------------------------------

resource "aws_api_gateway_rest_api" "lambda" {
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

resource "aws_api_gateway_deployment" "pir_query" {
  provider    = aws.infra
  rest_api_id = aws_api_gateway_rest_api.lambda.id
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

resource "aws_api_gateway_stage" "lambda" {
  provider      = aws.infra
  rest_api_id   = aws_api_gateway_rest_api.lambda.id
  stage_name    = "pir_query_lambda_stage"
  deployment_id = aws_api_gateway_deployment.pir_query.id

  # access_log_settings {
  #   destination_arn = aws_cloudwatch_log_group.api_gw.arn

  #   format = jsonencode({
  #     requestId               = "$context.requestId"
  #     sourceIp                = "$context.identity.sourceIp"
  #     requestTime             = "$context.requestTime"
  #     protocol                = "$context.protocol"
  #     httpMethod              = "$context.httpMethod"
  #     resourcePath            = "$context.resourcePath"
  #     routeKey                = "$context.routeKey"
  #     status                  = "$context.status"
  #     responseLength          = "$context.responseLength"
  #     integrationErrorMessage = "$context.integrationErrorMessage"
  #   })
  # }
}

resource "aws_api_gateway_resource" "query" {
  provider    = aws.infra
  parent_id   = aws_api_gateway_rest_api.lambda.root_resource_id
  path_part   = "query"
  rest_api_id = aws_api_gateway_rest_api.lambda.id
}


resource "aws_api_gateway_method" "query" {
  provider         = aws.infra
  rest_api_id      = aws_api_gateway_rest_api.lambda.id
  resource_id      = aws_api_gateway_resource.query.id
  http_method      = "POST"
  authorization    = "NONE"
  api_key_required = true
}

resource "aws_api_gateway_integration" "query" {
  provider                = aws.infra
  http_method             = aws_api_gateway_method.query.http_method
  resource_id             = aws_api_gateway_resource.query.id
  rest_api_id             = aws_api_gateway_rest_api.lambda.id
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/${aws_lambda_function.pir_query.arn}/invocations"
}

resource "aws_api_gateway_api_key" "general" {
  provider = aws.infra
  name     = "pir-query-general"
}

resource "aws_api_gateway_usage_plan" "pir_query" {
  provider = aws.infra
  name     = "pir-query-usage-plan"

  api_stages {
    api_id = aws_api_gateway_rest_api.lambda.id
    stage  = aws_api_gateway_stage.lambda.stage_name
  }

  # Optional but recommended
  throttle_settings {
    rate_limit  = 10
    burst_limit = 20
  }
}

resource "aws_api_gateway_usage_plan_key" "pir_query" {
  provider      = aws.infra
  key_id        = aws_api_gateway_api_key.general.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.pir_query.id
}

resource "aws_cloudwatch_log_group" "api_gw" {
  provider          = aws.infra
  name              = "/aws/api_gw/${aws_api_gateway_rest_api.lambda.name}"
  retention_in_days = 7
}

resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.pir_query.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.lambda.execution_arn}/*/*"
}

# ------------------------------------------------------------------
# WAF
# ------------------------------------------------------------------

resource "aws_wafv2_ip_set" "allowed" {
  provider           = aws.infra
  name               = "pir-query-allowed-ips"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"

  addresses = [for val in var.acf_vpn_ips : "${val}/32"]
}

resource "aws_wafv2_web_acl" "pir_query_acl" {
  provider = aws.infra
  name     = "pir-query-acl"
  scope    = "REGIONAL"

  default_action {
    allow {} # ← allow by default, block unknown IPs via rule below
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
            arn = aws_wafv2_ip_set.allowed.arn
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

resource "aws_wafv2_web_acl_association" "api_gw" {
  provider     = aws.infra
  resource_arn = "arn:aws:apigateway:us-east-1::/restapis/${aws_api_gateway_rest_api.lambda.id}/stages/${aws_api_gateway_stage.lambda.stage_name}"
  web_acl_arn  = aws_wafv2_web_acl.pir_query_acl.arn
  depends_on   = [aws_api_gateway_stage.lambda]
}

# ------------------------------------------------------------------
# Extract S3 Bucket
# ------------------------------------------------------------------

resource "aws_s3_bucket" "extracts" {
  provider = aws.infra
  bucket_prefix   = "pir-extracts-"
}

resource "aws_s3_bucket_lifecycle_configuration" "extracts" {
  provider = aws.infra
  bucket   = aws_s3_bucket.extracts.bucket
  rule {
    id = "pir-extract-expiry"
    expiration {
      days = 1
    }
    status = "Enabled"
  }
}

# resource "aws_vpc_endpoint" "extracts" {
#   provider          = aws.infra
#   vpc_id            = var.pir_vpc # the VPC containing rds_subnet_ids
#   service_name      = "com.amazonaws.us-east-1.s3"
#   vpc_endpoint_type = "Gateway"
#   route_table_ids   = var.pir_vpc_route_table_ids
# }

# resource "aws_s3_bucket_policy" "restrict_query_results" {
#   provider = aws.infra
#   bucket   = aws_s3_bucket.extracts.bucket
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Sid       = "DenyUnlessVpnOrVpc"
#         Effect    = "Deny"
#         Principal = "*"
#         Action    = "s3:GetObject"
#         Resource  = "${aws_s3_bucket.extracts.arn}/*"
#         Condition = {
#           NotIpAddress = {
#             "aws:SourceIp" = [for ip in var.acf_vpn_ips : "${ip}/32"]
#           }
#           # StringNotEquals = {
#           #   "aws:SourceVpce" = aws_vpc_endpoint.extracts.id
#           # }
#         }
#       }
#     ]
#   })
# }

resource "aws_s3_bucket_public_access_block" "extracts" {
  provider                = aws.infra
  bucket                  = aws_s3_bucket.extracts.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
