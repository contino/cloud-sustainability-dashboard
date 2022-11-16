terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 4.34.0"
      configuration_aliases = [aws.us_east_1]
    }
  }
}
