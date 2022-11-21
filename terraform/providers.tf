terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.34.0"
    }
    grafana = {
      source  = "grafana/grafana"
      version = ">= 1.13.3"
    }
  }
  backend "s3" {}
}

provider "aws" {
  region = var.region
}

provider "aws" {
  # for services that is only available in us east, i.e CUR
  alias  = "us_east_1"
  region = "us-east-1"
}

# The grafana/grafana provider has an issue where if a resource was created with it, and is in the state file,
# but not in the configuration files, terraform breaks with a 'provider not found'.
# A simple workaround is to create an alias to it, so terraform doesn't get confused
# provider "grafana" {
#   url  = "https://${aws_grafana_workspace.cloud_sustainability_dashboard.endpoint}" #"https://${module.gf_workspace.grafana_end_point}"
#   auth = aws_grafana_workspace_api_key.admin_key.key                                #module.gf_workspace.grafana_api_key
#   alias = "grafana"
# }
