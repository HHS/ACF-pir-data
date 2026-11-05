# ==================================================================
# PIR pipeline — shared Lambda build + IAM
# pir-pipeline/template.yaml (SAM) + the old query.tf -> Terraform
#
# All three functions (PirIngestor, PirLinker, PirQuery) share:
#   - one handler package (../src: handlers/ + pir_pipeline/), zipped once
#   - one deps layer (built from ../src/handlers/requirements.txt)
#   - one execution role
# Per-function config (memory, triggers, schedule, API) lives in lambda_*.tf.
# ==================================================================

data "aws_partition" "current" {
  provider = aws.infra
}

data "aws_region" "current" {
  provider = aws.infra
}

locals {
  partition          = data.aws_partition.current.partition
  region             = data.aws_region.current.region
  python_ver         = "python3.12"
  log_retention_days = 7

  src_dir      = "${path.module}/../src"
  requirements = "${local.src_dir}/handlers/requirements.txt"

  # Rebuild the layer only when the lock changes.
  deps_hash = filemd5(local.requirements)

  layer_name      = "pir-pipeline-layer"
  layer_build_dir = "${path.module}/.build/layer"
  layer_buildenv  = "${path.module}/.build/buildenv"
  layer_zip       = "${path.module}/.build/layer.zip"
  code_zip        = "${path.module}/.build/code.zip"

  # Environment shared by every function; each adds its own DB_SECRET_NAME.
  lambda_env = {
    IN_AWS_LAMBDA = "True"
  }
}

# ------------------------------------------------------------------
# Database secrets (must already exist; names have a random suffix)
#
# Both have the shape:
#   {"DB_CONFIG": {"user": ..., "password": ..., "host": ..., "port": ...},
#    "DB_NAME": ...}
# ------------------------------------------------------------------
data "aws_secretsmanager_secret" "query_config" {
  provider = aws.infra
  name     = "pir/query/config"
}

# Read/write credentials for PirIngestor and PirLinker (replaces the SAM
# DBUser/DBPassword/... stack parameters).
data "aws_secretsmanager_secret" "pipeline_config" {
  provider = aws.infra
  name     = "pir/pipeline/config"
}

# ------------------------------------------------------------------
# Deps layer
# ------------------------------------------------------------------
resource "null_resource" "build_layer" {
  triggers = { deps_hash = local.deps_hash }

  provisioner "local-exec" {
    working_dir = path.module
    command     = <<-EOT
      set -e
      rm -rf "${local.layer_build_dir}" "${local.layer_buildenv}"
      mkdir -p "${local.layer_build_dir}/python"

      # Isolated build env — never touches your project .venv. Kept outside
      # the layer dir so it doesn't end up in the layer zip, and removed as
      # soon as the build exits (success or failure).
      trap 'rm -rf "${local.layer_buildenv}"' EXIT
      python -m venv "${local.layer_buildenv}"
      "${local.layer_buildenv}/bin/python" -m pip install --quiet "pip==24.2"

      # Install target wheels for the Lambda platform from the pinned lock
      "${local.layer_buildenv}/bin/python" -m pip install \
        --platform manylinux_2_28_x86_64 \
        --platform manylinux2014_x86_64 \
        --implementation cp \
        --python-version ${replace(local.python_ver, "python", "")} \
        --only-binary=:all: \
        --target "${local.layer_build_dir}/python" \
        --requirement "${local.requirements}"
    EOT
  }
}

data "archive_file" "layer" {
  depends_on  = [null_resource.build_layer]
  type        = "zip"
  source_dir  = local.layer_build_dir
  output_path = local.layer_zip
}

resource "aws_s3_object" "layer" {
  provider = aws.infra
  bucket   = aws_s3_bucket.data.bucket
  key      = "code/pir-pipeline-layer.zip"
  source   = data.archive_file.layer.output_path
  etag     = data.archive_file.layer.output_md5
}

resource "aws_lambda_layer_version" "pir" {
  provider            = aws.infra
  layer_name          = local.layer_name
  s3_bucket           = aws_s3_bucket.data.bucket
  s3_key              = aws_s3_object.layer.key
  compatible_runtimes = [local.python_ver]
  description         = "PIR pipeline deps (hash: ${local.deps_hash})"
}

# ------------------------------------------------------------------
# Handler package: src/handlers + src/pir_pipeline
# ------------------------------------------------------------------
data "archive_file" "code" {
  type        = "zip"
  source_dir  = local.src_dir
  output_path = local.code_zip
  excludes = [
    "instance/**", # local Flask instance config
    "*.egg-info/**",
    "**/__pycache__/**",
  ]
}

resource "aws_s3_object" "code" {
  provider = aws.infra
  bucket   = aws_s3_bucket.data.bucket
  key      = "code/pir-pipeline-code.zip"
  source   = data.archive_file.code.output_path
  etag     = data.archive_file.code.output_md5
}

# ------------------------------------------------------------------
# Shared execution role
#
# Union of the SAM LambdaExecutionRole and the old PirQuery role, scoped
# down. Dropped from the SAM role because no handler uses them:
# lambda:InvokeFunction and events:PutTargets/PutRule/DeleteRule/DescribeRule.
# ------------------------------------------------------------------
resource "aws_iam_role" "pir_exec" {
  provider = aws.architect
  name     = "${var.project_name}-lambda"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

data "aws_iam_policy_document" "pir_rds" {
  statement {
    effect    = "Allow"
    actions   = ["rds:DescribeDBInstances", "rds:Connect", "rds:ExecuteStatement"]
    resources = [var.pir_rds_arn]
  }
}

# Scoped to the data and extract buckets. Drops "s3:ListObjects" and
# "s3:CopyObject", which are not IAM actions (the ingestor's s3.copy is
# GetObject + PutObject).
data "aws_iam_policy_document" "pir_s3" {
  statement {
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.data.arn, aws_s3_bucket.extracts.arn]
  }
  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["${aws_s3_bucket.data.arn}/*", "${aws_s3_bucket.extracts.arn}/*"]
  }
}

data "aws_iam_policy_document" "pir_ec2" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeVpcs",
      "ec2:AttachNetworkInterface",
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "pir_secrets" {
  statement {
    effect  = "Allow"
    actions = ["secretsmanager:GetSecretValue"]
    resources = [
      data.aws_secretsmanager_secret.query_config.arn,
      data.aws_secretsmanager_secret.pipeline_config.arn,
    ]
  }
}

# Replaces kms:Decrypt on "key/*". Scoped to keys used via Secrets Manager.
data "aws_iam_policy_document" "pir_kms" {
  statement {
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["secretsmanager.${local.region}.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "pir" {
  provider = aws.architect
  for_each = tomap({
    "rds"     = data.aws_iam_policy_document.pir_rds.json
    "s3"      = data.aws_iam_policy_document.pir_s3.json
    "ec2"     = data.aws_iam_policy_document.pir_ec2.json
    "secrets" = data.aws_iam_policy_document.pir_secrets.json
    "kms"     = data.aws_iam_policy_document.pir_kms.json
  })
  name   = "${var.project_name}-${each.key}"
  policy = each.value
}

resource "aws_iam_role_policy_attachment" "pir" {
  provider = aws.architect
  for_each = merge(
    { "basic" = "arn:${local.partition}:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole" },
    { for k, p in aws_iam_policy.pir : k => p.arn },
  )
  role       = aws_iam_role.pir_exec.name
  policy_arn = each.value
}
