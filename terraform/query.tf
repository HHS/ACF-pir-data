# Adapted from Claude

locals {
  layer_name = "pir-pipeline-layer"
  python_ver = "python3.12"
  build_dir  = "${path.module}/.build/layer"
  query_dir  = "${path.module}/.build/query"
  query_zip  = "${path.module}/.build/query.zip"
  zip_path   = "${path.module}/.build/layer.zip"
  # Hash pyproject.toml so the layer rebuilds only when deps change
  deps_hash = filemd5("${path.module}/../pyproject.toml")
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
        $(python3 -c "
import tomllib, sys
with open('../pyproject.toml', 'rb') as f:
    data = tomllib.load(f)
deps = data.get('project', {}).get('dependencies', [])
# Strip version markers to get bare package names for pip
print(' '.join(deps))
        ")
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
  s3_bucket = var.pir_s3_name
  s3_key = aws_s3_object.pir_query_layer.key
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
  layers = [aws_lambda_layer_version.this.arn]
  depends_on = [aws_s3_object.pir_query_code]
}

resource "aws_cloudwatch_log_group" "pir_query" {
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
    actions = ["s3:ListBucket", "s3:ListObjects"]
    effect    = "Allow"
    resources = [var.pir_s3_arn]
  }
  statement {
    actions   = ["s3:GetObject", "s3:PutObject", "s3:CopyObject", "s3:DeleteObject"]
    effect    = "Allow"
    resources = ["${var.pir_s3_arn}/*"]
  }
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


resource "aws_iam_role_policy_attachment" "lambda_policy" {
  for_each   = tomap({ "lambda" = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole", "rds" = aws_iam_policy.pir_rds_policy.arn, "s3" = aws_iam_policy.pir_s3_policy.arn, "ec2" = aws_iam_policy.pir_ec2_policy.arn })
  role       = aws_iam_role.lambda_exec.name
  policy_arn = each.value
}

# ------------------------------------------------------------------
# Create API Gateway
# ------------------------------------------------------------------

resource "aws_apigatewayv2_api" "lambda" {
  provider = aws.infra
  name          = "serverless_lambda_gw"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "lambda" {
  provider = aws.infra
  api_id      = aws_apigatewayv2_api.lambda.id
  name        = "serverless_lambda_stage"
  auto_deploy = true
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw.arn

    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourcePath            = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
    })
  }
}

resource "aws_apigatewayv2_integration" "pir_query" {
  provider = aws.infra
  api_id             = aws_apigatewayv2_api.lambda.id
  integration_uri    = aws_lambda_function.pir_query.invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
  payload_format_version = "1.0"
}

resource "aws_apigatewayv2_route" "pir_query" {
  provider = aws.infra
  api_id = aws_apigatewayv2_api.lambda.id

  route_key = "POST /query"
  target    = "integrations/${aws_apigatewayv2_integration.pir_query.id}"
}

resource "aws_cloudwatch_log_group" "api_gw" {
  provider = aws.infra
  name              = "/aws/api_gw/${aws_apigatewayv2_api.lambda.name}"
  retention_in_days = 7
}

resource "aws_lambda_permission" "api_gw" {
  provider = aws.infra
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.pir_query.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.lambda.execution_arn}/*/*"
}

# ------------------------------------------------------------------
# WAF
# ------------------------------------------------------------------

resource "aws_wafv2_ip_set" "allowed" {
  provider = aws.infra
  name               = "pir-query-allowed-ips"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"

  addresses = [for val in var.acf_vpn_ips : "${val}/32"]
}

resource "aws_wafv2_web_acl" "pir_query_acl" {
  provider = aws.infra
  name  = "pir-query-acl"
  scope = "REGIONAL"
  default_action {
    block {}
  }
  rule {
    name     = "allow-acf-ips"
    priority = 1
    action {
      allow {}
    }
    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.allowed.arn
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AllowKnownIPs"
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
  provider = aws.infra
  # resource_arn = "arn:aws:apigateway:us-east-1:${var.account_id}:/apis/${aws_apigatewayv2_api.lambda.id}/stages/${aws_apigatewayv2_stage.lambda.name}"
  resource_arn = aws_apigatewayv2_stage.lambda.arn
  web_acl_arn  = aws_wafv2_web_acl.pir_query_acl.arn
}
