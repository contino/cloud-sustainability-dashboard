variable "name" {
  description = "The name of this resource"
  type        = string
}

variable "region" {
  description = "The region to build the resources in"
}

variable "handler" {
  description = "The handler to call for the lambda"
  type        = string
}

variable "path" {
  description = "The path to the lambda. Needs to be a folder that gets zipped and uploaded"
  type        = string
}

variable "bucket_name" {
  description = "The bucket to store the output"
  type        = string
}

variable "glue_database_name" {
  description = "The name of the glue database"
  type        = string
}

variable "kms_key_arn" {
  description = "The arn to the kms key for encrypting the bucket"
  type        = string
}

variable "glue_table_arns" {
  description = "A list of glue table arns that needs partition permission"
  type        = list(string)
}

variable "s3_prefixes" {
  description = "A list of s3 prefixed that the lambda needs write permission to for dumping the collected data"
  type        = list(string)
}

variable "env_vars" {
  description = "A map of environment variables for the lambda, with strings as values"
  type        = map(string)

}

variable "additional_iam_policies" {
  description = "A list of additional iam policies, consisting of a name and a policy"
  default     = []
  type        = list(map(string))

}