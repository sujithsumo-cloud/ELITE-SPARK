# ============================================================
# HYDERABAD PRIMARY S3 BUCKET
# ============================================================

resource "aws_s3_bucket" "finance" {
  bucket_prefix = "elite-spark-finance-hyd-"

  tags = {
    Name        = "HYD-FINANCE-S3"
    Application = "finance-app"
  }
}

# ============================================================
# VERSIONING
# ============================================================

resource "aws_s3_bucket_versioning" "finance" {
  bucket = aws_s3_bucket.finance.id

  versioning_configuration {
    status = "Enabled"
  }
}

# ============================================================
# SERVER-SIDE ENCRYPTION
# ============================================================

resource "aws_s3_bucket_server_side_encryption_configuration" "finance" {
  bucket = aws_s3_bucket.finance.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# ============================================================
# LIFECYCLE
# Older non-current versions are deleted after 30 days.
# ============================================================

resource "aws_s3_bucket_lifecycle_configuration" "finance" {
  bucket = aws_s3_bucket.finance.id

  depends_on = [
    aws_s3_bucket_versioning.finance
  ]

  rule {
    id     = "cleanup-old-versions"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}