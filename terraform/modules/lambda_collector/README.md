# lambda collector
A slightly oppinionated module for creating and deploying lambda collectors, setting permissions, and triggering them on a cron.

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_archive"></a> [archive](#provider\_archive) | n/a |
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_event_rule.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_target.collect_resource_data](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_iam_role.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_lambda_function.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_lambda_permission.collect_resource_data](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [archive_file.this](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [aws_iam_policy_document.lambda_execution_role_trust_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_iam_policies"></a> [additional\_iam\_policies](#input\_additional\_iam\_policies) | A list of additional iam policies, consisting of a name and a policy | `list(map(string))` | `[]` | no |
| <a name="input_bucket_name"></a> [bucket\_name](#input\_bucket\_name) | The bucket to store the output | `string` | n/a | yes |
| <a name="input_env_vars"></a> [env\_vars](#input\_env\_vars) | A map of environment variables for the lambda, with strings as values | `map(string)` | n/a | yes |
| <a name="input_handler"></a> [handler](#input\_handler) | The handler to call for the lambda | `string` | n/a | yes |
| <a name="input_iam_bucket_resources"></a> [iam\_bucket\_resources](#input\_iam\_bucket\_resources) | A list of arns [arn, arn] that the lambda needs write permission to, for dumping the collected data | `list(string)` | n/a | yes |
| <a name="input_kms_key_arn"></a> [kms\_key\_arn](#input\_kms\_key\_arn) | The arn to the kms key for encrypting the bucket | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | The name of this resource | `string` | n/a | yes |
| <a name="input_path"></a> [path](#input\_path) | The path to the lambda. Needs to be a folder that gets zipped and uploaded | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->