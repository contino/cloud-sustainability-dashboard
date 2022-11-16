output "glue_database_name" {
  value = aws_glue_catalog_database.metrics.name
}

output "glue_database_arn" {
  value = aws_glue_catalog_database.metrics.arn
}

output "raw_s3_bucket_name" {
  value = aws_s3_bucket.raw_data.id
}

output "raw_s3_bucket_arn" {
  value = aws_s3_bucket.raw_data.arn
}

output "kms_key_arn" {
  value = aws_kms_key.this.arn
}

output "kms_key_alias" {
  value = aws_kms_alias.this.name
}

