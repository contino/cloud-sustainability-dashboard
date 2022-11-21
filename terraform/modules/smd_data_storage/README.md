# Terraform module - Sustainability Metrics Dashboard - Shared Data Ingestion & Storage Resources

Terraform module to create shared data resources (S3, KMS, Glue Database) that will be used to store sustainability data.
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 2.7.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 2.7.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_glue_catalog_database.metrics](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/glue_catalog_database) | resource |
| [aws_kms_alias.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_s3_bucket.raw_data](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_public_access_block.raw_data](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.raw_data](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_glue_database_name"></a> [glue\_database\_name](#input\_glue\_database\_name) | Name of the glue database to be created that will store sustainability metrics data | `string` | n/a | yes |
| <a name="input_kms_key_alias"></a> [kms\_key\_alias](#input\_kms\_key\_alias) | Alias for KMS key to be created | `string` | n/a | yes |
| <a name="input_s3_raw_data_bucket_prefix"></a> [s3\_raw\_data\_bucket\_prefix](#input\_s3\_raw\_data\_bucket\_prefix) | Name of the prefix for the S3 bucket to be created where raw data will be uploaded | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_glue_database_name"></a> [glue\_database\_name](#output\_glue\_database\_name) | n/a |
| <a name="output_kms_key_alias"></a> [kms\_key\_alias](#output\_kms\_key\_alias) | n/a |
| <a name="output_kms_key_arn"></a> [kms\_key\_arn](#output\_kms\_key\_arn) | n/a |
| <a name="output_raw_s3_bucket_name"></a> [raw\_s3\_bucket\_name](#output\_raw\_s3\_bucket\_name) | n/a |
