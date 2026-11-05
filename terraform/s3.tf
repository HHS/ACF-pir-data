# ------------------------------------------------------------------
# Data bucket (was template.yaml S3Bucket "pir-data-files")
#
# bucket_prefix, not a fixed name: AWS appends a random suffix, so this is
# a NEW bucket. The old pir-data-files bucket is left alone (it was
# DeletionPolicy: Retain); move anything worth keeping by hand.
#
# Layout:
#   input/      drop PIR exports here -> triggers PirIngestor
#   processed/  PirIngestor moves files here after ingesting
#   code/       deploy artifacts (doesn't trigger anything)
# ------------------------------------------------------------------
resource "aws_s3_bucket" "data" {
  provider      = aws.infra
  bucket_prefix = "pir-data-files-"

  lifecycle {
    prevent_destroy = true # mirrors DeletionPolicy/UpdateReplacePolicy: Retain
  }
}

resource "aws_s3_bucket_public_access_block" "data" {
  provider                = aws.infra
  bucket                  = aws_s3_bucket.data.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ------------------------------------------------------------------
# Extract bucket: PirQuery writes result sets here and returns a
# presigned URL. Objects expire after a day.
# ------------------------------------------------------------------
resource "aws_s3_bucket" "extracts" {
  provider      = aws.infra
  bucket_prefix = "pir-extracts-"
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

resource "aws_s3_bucket_public_access_block" "extracts" {
  provider                = aws.infra
  bucket                  = aws_s3_bucket.extracts.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
