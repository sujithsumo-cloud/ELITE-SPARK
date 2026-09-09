# ============================================================
# MUMBAI DR S3 BUCKET
#
# Destination bucket for S3 Cross-Region Replication
#
# Source:
#   Hyderabad ap-south-2
#
# Destination:
#   Mumbai ap-south-1
# ============================================================


# ------------------------------------------------------------
# RANDOM UNIQUE SUFFIX
# ------------------------------------------------------------

resource "random_id" "mum_s3_suffix" {
  byte_length = 8
}


# ------------------------------------------------------------
# MUMBAI DR BUCKET
# ------------------------------------------------------------

resource "aws_s3_bucket" "finance_dr" {

  bucket = "elite-spark-finance-mum-${random_id.mum_s3_suffix.hex}"

  tags = {
    Name        = "MUM-FINANCE-DR-BUCKET"
    Application = "finance-app"
    Purpose     = "Cross-Region-Replication"
  }
}


# ------------------------------------------------------------
# VERSIONING
#
# Required for S3 replication.
# ------------------------------------------------------------

resource "aws_s3_bucket_versioning" "finance_dr" {

  bucket = aws_s3_bucket.finance_dr.id

  versioning_configuration {
    status = "Enabled"
  }
}


# ------------------------------------------------------------
# SERVER-SIDE ENCRYPTION
# ------------------------------------------------------------

resource "aws_s3_bucket_server_side_encryption_configuration" "finance_dr" {

  bucket = aws_s3_bucket.finance_dr.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}


# ------------------------------------------------------------
# BLOCK PUBLIC ACCESS
# ------------------------------------------------------------

resource "aws_s3_bucket_public_access_block" "finance_dr" {

  bucket = aws_s3_bucket.finance_dr.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


# ------------------------------------------------------------
# LIFECYCLE
#
# Keep older object versions for 30 days.
# ------------------------------------------------------------

resource "aws_s3_bucket_lifecycle_configuration" "finance_dr" {

  bucket = aws_s3_bucket.finance_dr.id

  depends_on = [
    aws_s3_bucket_versioning.finance_dr
  ]

  rule {
    id     = "expire-old-versions"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}