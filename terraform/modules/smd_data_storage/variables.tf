variable "s3_raw_data_bucket_prefix" {
  type        = string
  description = "Name of the prefix for the S3 bucket to be created where raw data will be uploaded"
}

variable "glue_database_name" {
  type        = string
  description = "Name of the glue database to be created that will store sustainability metrics data"
}

variable "kms_key_alias" {
  type        = string
  description = "Alias for KMS key to be created"
}
