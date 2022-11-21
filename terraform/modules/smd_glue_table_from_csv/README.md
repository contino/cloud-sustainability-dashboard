# Terraform module - Glue table from CSV

Terraform module to create a Glue Table from a CSV files. Uploads files to S3 and creates glue catalog table. 

## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_glue_catalog_table.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/glue_catalog_table) | resource |
| [aws_s3_object.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_columns"></a> [columns](#input\_columns) | List of maps defining the columns of the glue table | `list(any)` | n/a | yes |
| <a name="input_csv_files"></a> [csv\_files](#input\_csv\_files) | List of maps, for each CSV detailing the local\_path of the csv and the s3\_key to upload to | `list(any)` | n/a | yes |
| <a name="input_glue_database_name"></a> [glue\_database\_name](#input\_glue\_database\_name) | Name of an existing glue database where table will be created | `string` | n/a | yes |
| <a name="input_glue_table_name"></a> [glue\_table\_name](#input\_glue\_table\_name) | Name of the glue catalog table to be created | `string` | n/a | yes |
| <a name="input_s3_bucket_name"></a> [s3\_bucket\_name](#input\_s3\_bucket\_name) | Name of the S3 bucket where CSV files will be uploaded | `string` | n/a | yes |
| <a name="input_s3_table_location"></a> [s3\_table\_location](#input\_s3\_table\_location) | S3 URI for the S3 location of the glue table | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_glue_table_name"></a> [glue\_table\_name](#output\_glue\_table\_name) | n/a |
