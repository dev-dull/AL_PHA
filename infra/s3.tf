# ------------------------------------------------------
# S3 — one-time migration transfer bucket
# ------------------------------------------------------

resource "aws_s3_bucket" "migrations" {
  bucket = "${var.project}-migrations-${data.aws_caller_identity.current.account_id}"

  tags = { Name = "${var.project}-migrations" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "migrations" {
  bucket = aws_s3_bucket.migrations.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "migrations" {
  bucket = aws_s3_bucket.migrations.id

  rule {
    id     = "expire-migration-blobs"
    status = "Enabled"

    filter {
      prefix = "migrations/"
    }

    expiration {
      days = 1 # 24-hour TTL
    }
  }
}

resource "aws_s3_bucket_public_access_block" "migrations" {
  bucket = aws_s3_bucket.migrations.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
