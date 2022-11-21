# cloud-sustainability-dashboard: CUR stack

This is a terraform version of the AWS provided cfn that gets generated when a CUR is created.
https://docs.aws.amazon.com/cur/latest/userguide/use-athena-cf.html

It has a few differrences, most notibly better names, it creates a bucket, and the lamda that created the bucket notification is just a aws_s3_bucket_notification resource


## Usage

```
module "CUR_stack" {
  source = "./modules/terraform_CUR_stack_aws"
  name   = "sustainability-report"
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 4.34.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 4.34.0 |
| <a name="provider_aws.east"></a> [aws.east](#provider\_aws.east) | 4.34.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cur_report_definition.cur_report_definition](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cur_report_definition) | resource |
| [aws_glue_catalog_database.aws_glue_catalog_database](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/glue_catalog_database) | resource |
| [aws_glue_catalog_table.aws_glue_catalog_table](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/glue_catalog_table) | resource |
| [aws_glue_crawler.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/glue_crawler) | resource |
| [aws_iam_role.crawler_component](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.crawler_lamda_executor](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_kms_key.key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_lambda_function.cur_crawler_notifier](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_lambda_permission.allow_s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_s3_bucket.bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_notification.bucket_notification](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_notification) | resource |
| [aws_s3_bucket_policy.cur_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.encrypt_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [archive_file.crawler_trigger](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [aws_iam_policy_document.glue-assume-role-policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.lamda-assume-role-policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.s3_cur_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_create_bucket"></a> [create\_bucket](#input\_create\_bucket) | n/a | `bool` | `true` | no |
| <a name="input_create_cur"></a> [create\_cur](#input\_create\_cur) | n/a | `bool` | `true` | no |
| <a name="input_cur_time_unit"></a> [cur\_time\_unit](#input\_cur\_time\_unit) | n/a | `string` | `"DAILY"` | no |
| <a name="input_name"></a> [name](#input\_name) | n/a | `string` | `"sustainability-report"` | no |
| <a name="input_region"></a> [region](#input\_region) | n/a | `string` | `"eu-west-2"` | no |
| <a name="input_s3-prefix"></a> [s3-prefix](#input\_s3-prefix) | n/a | `string` | `"report"` | no |
| <a name="input_s3_bucket"></a> [s3\_bucket](#input\_s3\_bucket) | n/a | `string` | `"sustainability-report-bucket"` | no |
| <a name="input_status_table_name"></a> [status\_table\_name](#input\_status\_table\_name) | n/a | `string` | `"cost_and_usage_data_status"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_data_table_name"></a> [data\_table\_name](#output\_data\_table\_name) | n/a |
| <a name="output_database_name"></a> [database\_name](#output\_database\_name) | n/a |
| <a name="output_status_table_name"></a> [status\_table\_name](#output\_status\_table\_name) | n/a |
| <a name="output_workgroup"></a> [workgroup](#output\_workgroup) | n/a |
<!-- END_TF_DOCS -->