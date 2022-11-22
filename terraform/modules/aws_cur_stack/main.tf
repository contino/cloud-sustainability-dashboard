# This is build as per AWS generated cloufromation.
# TODO: Refactor to use best practices
resource "aws_s3_bucket" "bucket" {
  # checkov:skip=CKV_AWS_144: This bucket does not need to be multi region
  # checkov:skip=CKV_AWS_21:  This bucket does not need to be versioned
  # checkov:skip=CKV_AWS_18:  TODO: Enable bucket logging
  # checkov:skip=CKV2_AWS_6:  TEnsure that S3 bucket has a Public Access block
  count  = var.create_bucket ? 1 : 0
  bucket = var.s3_bucket
}

resource "aws_s3_bucket_policy" "cur_access" {
  count  = var.create_bucket ? 1 : 0
  bucket = aws_s3_bucket.bucket[0].id
  policy = data.aws_iam_policy_document.s3_cur_access[0].json
}

resource "aws_kms_key" "key" {
  count               = var.create_bucket ? 1 : 0
  description         = "This key is used to encrypt ${var.s3_bucket} objects"
  enable_key_rotation = "true"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "encrypt_bucket" {
  count  = var.create_bucket ? 1 : 0
  bucket = aws_s3_bucket.bucket[0].bucket

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.key[0].arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "cur_public_block" {
  count                   = var.create_bucket ? 1 : 0
  bucket                  = aws_s3_bucket.bucket[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


resource "aws_cur_report_definition" "cur_report_definition" {
  count                = var.create_cur ? 1 : 0
  report_name          = var.cur_report_name
  time_unit            = var.cur_time_unit
  format               = "Parquet"
  compression          = "Parquet"
  s3_bucket            = var.s3_bucket
  s3_prefix            = var.s3_prefix
  s3_region            = var.region
  additional_artifacts = ["ATHENA"]
  report_versioning    = "OVERWRITE_REPORT"
  depends_on = [
    aws_s3_bucket.bucket[0],
    aws_s3_bucket_policy.cur_access
  ]
  # Required, not sure why
  additional_schema_elements = ["RESOURCES"]
  provider                   = aws.us_east_1
}

resource "aws_iam_role" "crawler_component" {
  name               = "${var.cur_report_name}-Crawler-Component"
  assume_role_policy = data.aws_iam_policy_document.glue-assume-role-policy.json
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole",
  "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"]

  inline_policy {
    name = "AWSCURCrawlerComponentFunction"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "glue:UpdateDatabase",
            "glue:UpdatePartition",
            "glue:CreateTable",
            "glue:UpdateTable",
          "glue:ImportCatalogToGlue"]
          Effect   = "Allow"
          Resource = "*"
        },
        {
          Action = [
            "s3:GetObject",
          "s3:PutObject"]
          Effect   = "Allow"
          Resource = "arn:aws:s3:::${var.s3_bucket}/${var.s3_prefix}/${var.cur_report_name}/${var.cur_report_name}*"
        },
      ]
    })
  }

  inline_policy {
    name = "AWSCURKMSDecryption"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action   = ["kms:Decrypt"]
          Effect   = "Allow"
          Resource = "*"
        },
      ]
    })
  }
}


resource "aws_iam_role" "crawler_lambda_executor" {
  # checkov:skip=CKV_AWS_272:Ensure AWS Lambda function is configured to validate code-signing
  # checkov:skip=CKV_AWS_173:Check encryption settings for Lambda environmental variable
  # checkov:skip=CKV_AWS_116:Ensure that AWS Lambda function is configured for a Dead Letter Queue(DLQ)
  # checkov:skip=CKV_AWS_117:Ensure that AWS Lambda function is configured inside a VPC
  name                = "${var.cur_report_name}-Crawler-Lambda-Excutor"
  assume_role_policy  = data.aws_iam_policy_document.lambda-assume-role-policy.json
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"]

  inline_policy {
    name = "AWSCURCrawlerLambdaExecutor"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action   = ["glue:StartCrawler"]
          Effect   = "Allow"
          Resource = "*"
        }
      ]
    })
  }
}

resource "aws_glue_catalog_database" "aws_glue_catalog_database" {
  name = var.cur_report_name
}

resource "aws_glue_catalog_table" "aws_glue_catalog_table" {
  name          = var.status_table_name
  database_name = aws_glue_catalog_database.aws_glue_catalog_database.name
  table_type    = "EXTERNAL_TABLE"
  storage_descriptor {
    input_format  = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    ser_de_info {
      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"
    }
    location = "s3://${var.s3_bucket}/${var.s3_prefix}/${var.cur_report_name}/cost_and_usage_data_status/"
    columns {
      name = "status"
      type = "string"
    }
  }

}


resource "aws_glue_crawler" "this" {
  # checkov:skip=CKV_AWS_195: TODO:This is AWS provided, but we should refactor to be using best practices
  description   = "A recurring crawler that keeps your CUR table in Athena up-to-date."
  database_name = aws_glue_catalog_database.aws_glue_catalog_database.name
  name          = "${var.cur_report_name}-crawler"
  role          = aws_iam_role.crawler_component.arn

  s3_target {
    path = "s3://${var.s3_bucket}/${var.s3_prefix}/${var.cur_report_name}/${var.cur_report_name}/"
    exclusions = [
      "**.json",
      "**.yml",
      "**.sql",
      "**.csv",
      "**.gz",
      "**.zip"
    ]
  }
  schema_change_policy {
    delete_behavior = "DELETE_FROM_DATABASE"
    update_behavior = "UPDATE_IN_DATABASE"
  }
}

resource "aws_lambda_function" "cur_crawler_notifier" {
  # checkov:skip=CKV_AWS_272:Ensure AWS Lambda function is configured to validate code-signing
  # checkov:skip=CKV_AWS_173:Check encryption settings for Lambda environmental variable
  # checkov:skip=CKV_AWS_116:Ensure that AWS Lambda function is configured for a Dead Letter Queue(DLQ)
  # checkov:skip=CKV_AWS_117:Ensure that AWS Lambda function is configured inside a VPC
  function_name                  = "${var.cur_report_name}_cur_crawler_notifier"
  handler                        = "index.handler"
  timeout                        = 30
  runtime                        = "nodejs16.x"
  reserved_concurrent_executions = 1
  role                           = aws_iam_role.crawler_lambda_executor.arn
  filename                       = data.archive_file.crawler_trigger.output_path
  source_code_hash               = data.archive_file.crawler_trigger.output_base64sha256
  environment {
    variables = {
      CRAWLER_NAME = aws_glue_crawler.this.name
    }
  }
  tracing_config {
    mode = "Active"
  }
}

resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cur_crawler_notifier.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${var.s3_bucket}"
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = var.s3_bucket

  lambda_function {
    lambda_function_arn = aws_lambda_function.cur_crawler_notifier.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "${var.s3_prefix}/${var.cur_report_name}/${var.cur_report_name}"
  }

  depends_on = [aws_lambda_permission.allow_s3]
}
