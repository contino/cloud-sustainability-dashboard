data "aws_caller_identity" "current" {}

locals {
  full_name        = "sustainability-report-${var.name}"
  bucket_resources = [for v in var.s3_prefixes : "arn:aws:s3:::${var.bucket_name}/${v}*"]
}

resource "aws_iam_role" "this" {
  name                = local.full_name
  assume_role_policy  = data.aws_iam_policy_document.lambda_execution_role_trust_policy.json
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"]

  inline_policy {
    name = "WriteS3"
    # tfsec:ignore:aws-iam-no-policy-wildcards   Buckets can have wildcards for subfolders
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "s3:GetObject",
            "s3:PutObject",
          "s3:DeleteObject"]
          Effect   = "Allow"
          Resource = local.bucket_resources
        },
      ]
    })
  }

  inline_policy {
    name = "ListS3"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
          "s3:ListBucket"]
          Effect = "Allow"
          Resource = [
            "arn:aws:s3:::${var.bucket_name}"
          ]
        },
      ]
    })
  }

  inline_policy {
    name = "KMSEncrypt"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "kms:Encrypt",
            "kms:Decrypt",
          "kms:GenerateDataKey"]
          Effect   = "Allow"
          Resource = var.kms_key_arn
        },
      ]
    })
  }

  inline_policy {
    name = "GlueCatalogRead"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "glue:GetTable",
          "glue:CreatePartition"]
          Effect = "Allow"
          Resource = ["arn:aws:glue:${var.region}:${data.aws_caller_identity.current.account_id}:catalog",
            "arn:aws:glue:${var.region}:${data.aws_caller_identity.current.account_id}:table/${var.glue_database_name}/",
          "arn:aws:glue:${var.region}:${data.aws_caller_identity.current.account_id}:database/${var.glue_database_name}"]
        },
      ]
    })
  }

  inline_policy {
    name = "GlueTablePartition"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "glue:GetTable",
          "glue:CreatePartition"]
          Effect   = "Allow"
          Resource = var.glue_table_arns
        },
      ]
    })
  }

  inline_policy {
    name = "Project_specific"
    # tfsec:ignore:aws-iam-no-policy-wildcards   Wildcard is for all regions
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
          "ec2:DescribeRegions"]
          Effect   = "Allow"
          Resource = "*"
        },
      ]
    })
  }

  dynamic "inline_policy" {
    for_each = var.additional_iam_policies
    content {
      name   = inline_policy.value.name
      policy = inline_policy.value.policy
    }
  }

}


resource "aws_lambda_function" "this" {
  # checkov:skip=CKV_AWS_272:Ensure AWS Lambda function is configured to validate code-signing
  # checkov:skip=CKV_AWS_173:Check encryption settings for Lambda environmental variable
  # checkov:skip=CKV_AWS_116:Ensure that AWS Lambda function is configured for a Dead Letter Queue(DLQ)
  # checkov:skip=CKV_AWS_117:Ensure that AWS Lambda function is configured inside a VPC
  function_name = local.full_name
  handler       = var.handler
  timeout       = 300
  runtime       = "python3.9"
  layers = [
    "arn:aws:lambda:${var.region}:017000801446:layer:AWSLambdaPowertoolsPython:39",
  "arn:aws:lambda:${var.region}:336392948345:layer:AWSSDKPandas-Python39:1"]
  reserved_concurrent_executions = 1
  role                           = aws_iam_role.this.arn
  filename                       = data.archive_file.this.output_path
  source_code_hash               = data.archive_file.this.output_base64sha256
  memory_size                    = 256
  environment {
    variables = var.env_vars
  }
  tracing_config {
    mode = "Active"
  }
}

resource "aws_cloudwatch_event_rule" "this" {
  name                = "${local.full_name}-event-rule"
  description         = "Trigger s3_collect Lambda at set intervals"
  schedule_expression = "cron(0 20 * * ? *)"
}

resource "aws_cloudwatch_event_target" "collect_resource_data" {
  arn  = aws_lambda_function.this.arn
  rule = aws_cloudwatch_event_rule.this.name
}

resource "aws_lambda_permission" "collect_resource_data" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.this.arn
}
