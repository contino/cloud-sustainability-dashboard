variable "cur_report_name" {
  default = "sustainability-report"
}

variable "region" {
  description = "The region to build the resources in"
}

variable "s3_bucket" {
  default = "sustainability-report-bucket"
}

variable "create_bucket" {
  default = true
}

variable "create_cur" {
  default = true
}

variable "cur_time_unit" {
  default = "DAILY"
}

variable "s3_prefix" {
  default = "report"
}

variable "status_table_name" {
  default = "cost_and_usage_data_status"
}
