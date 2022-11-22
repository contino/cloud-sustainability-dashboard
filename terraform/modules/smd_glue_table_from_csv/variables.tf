variable "s3_bucket_name" {
  type        = string
  description = "Name of the S3 bucket where CSV files will be uploaded"
}

variable "glue_database_name" {
  type        = string
  description = "Name of an existing glue database where table will be created"
}

variable "glue_table_name" {
  type        = string
  description = "Name of the glue catalog table to be created"
}

variable "s3_table_location" {
  type        = string
  description = "S3 URI for the S3 location of the glue table "
}

variable "csv_files" {
  type        = list(any)
  description = "List of maps, for each CSV detailing the local_path of the csv and the s3_key to upload to"
}

variable "columns" {
  type        = list(any)
  description = "List of maps defining the columns of the glue table"
}
