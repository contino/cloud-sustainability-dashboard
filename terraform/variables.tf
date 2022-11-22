variable "region" {
  type    = string
  default = "eu-west-2"
}

variable "glue_database_name" {
  description = "The glue database name."
  type        = string
  default     = "sustainability_metrics_dashboard_data"
}

variable "grafana_api_key_ttl" {
  description = <<EOT
Seconds for the grafana api key to live.
This key is billed Monthly, so could be expensive to create often.
On the other side, the value is stored in TF state, so a long lived key
can be considered bad practice. Recommended values are:
31 Days : 2678400 or 1 Day: 86400
EOT
  type        = number
  default     = 86400
}

variable "create_managed_grafana" {
  description = <<EOT
Boolean for wether to create a managed grafana dashboard.
Set to false if you are already running grafana.
Due to AWS grafana pricing, this can be very expensive, especially when recreating often.
EOT
  type        = bool
  default     = true
}

variable "create_grafana_datasources" {
  description = "Boolean for creating the required grafana datasources."
  type        = bool
  default     = true
}

variable "cur_s3_bucket_name" {
  default = "sustainability-report-bucket"
}
