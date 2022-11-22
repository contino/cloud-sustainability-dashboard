resource "aws_glue_catalog_database" "metrics" {
  name = var.glue_database_name
}


resource "aws_s3_bucket" "raw_data" {
  # checkov:skip=CKV_AWS_144: This bucket does not need to be multi region
  # checkov:skip=CKV_AWS_21:  This bucket does not need to be versioned
  # checkov:skip=CKV_AWS_18:  TODO: Enable bucket logging
  bucket_prefix = var.s3_raw_data_bucket_prefix
}

resource "aws_s3_bucket_server_side_encryption_configuration" "raw_data" {
  bucket = aws_s3_bucket.raw_data.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.this.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "raw_data" {
  bucket                  = aws_s3_bucket.raw_data.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_kms_key" "this" {
  description         = "KMS key for cloud sustainability metrics"
  enable_key_rotation = "true"
}

resource "aws_kms_alias" "this" {
  name          = var.kms_key_alias
  target_key_id = aws_kms_key.this.key_id
}
