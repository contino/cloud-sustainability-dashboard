################################################################################
# AWS Cost and Usage Report setup
################################################################################

module "CUR_stack" {
  source          = "./modules/aws_cur_stack"
  cur_report_name = "sustainability-report"
  region          = var.region
  s3_bucket       = var.cur_s3_bucket_name

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }
}

################################################################################
# Shared Glue, S3 and KMS resources
################################################################################

module "shared_storage" {
  source = "./modules/smd_data_storage"

  s3_raw_data_bucket_prefix = "cloud-sustainability-metrics-raw"
  glue_database_name        = var.glue_database_name
  kms_key_alias             = "alias/sustainability-metrics"
}

################################################################################
# Static CSV Files
################################################################################

locals {
  static_csv_files = [
    {
      file_name  = "aws-carbon-intensity.csv"
      table_name = "carbon_intensity"
      s3_prefix  = "aws_carbon_intensity"
      columns = [
        {
          name = "region"
          type = "string"
        },
        {
          name = "country"
          type = "string"
        },
        {
          name = "source_area"
          type = "string"
        },
        {
          name = "date_retrieved"
          type = "date"
        },
        {
          name = "co2e"
          type = "float"
        },
        {
          name = "source"
          type = "string"
        }
      ]
    },
    {
      file_name  = "aws-instances.csv"
      table_name = "aws_instances"
      s3_prefix  = "aws_instances"
      columns = [
        {
          name = "instance type"
          type = "string"
        },
        {
          name = "release date"
          type = "string"
        },
        {
          name = "instance vpcu"
          type = "int"
        },
        {
          name = "platform total number of vpcu"
          type = "int"
        },
        {
          name = "platform cpu name"
          type = "string"
        },
        {
          name = "instance memory (in gb)"
          type = "int"
        },
        {
          name = "platform memory (in gb)"
          type = "int"
        },
        {
          name = "storage info (type and size in gb)"
          type = "string"
        },
        {
          name = "storage type"
          type = "string"
        },
        {
          name = "platform storage drive quantity"
          type = "int"
        },
        {
          name = "platform gpu quantity"
          type = "string"
        },
        {
          name = "platform gpu name"
          type = "string"
        },
        {
          name = "instance number of gpu"
          type = "string"
        },
        {
          name = "instance gpu memory (in gb)"
          type = "string"
        },
        {
          name = "pkgwatt @ idle"
          type = "float"
        },
        {
          name = "pkgwatt @ 10%"
          type = "float"
        },
        {
          name = "pkgwatt @ 50%"
          type = "float"
        },
        {
          name = "pkgwatt @ 100%"
          type = "float"
        },
        {
          name = "pkgwatt @ idle"
          type = "float"
        },
        {
          name = "ramwatt @ 10%"
          type = "float"
        },
        {
          name = "ramwatt @ 50%"
          type = "float"
        },
        {
          name = "ramwatt @ 100%"
          type = "float"
        },
        {
          name = "gpuwatt @ idle"
          type = "float"
        },
        {
          name = "gpuwatt @ 10%"
          type = "float"
        },
        {
          name = "gpuwatt @ 50%"
          type = "float"
        },
        {
          name = "gpuwatt @ 100%"
          type = "float"
        },
        {
          name = "delta full machine"
          type = "float"
        },
        {
          name = "instance @ idle"
          type = "float"
        },
        {
          name = "instance @ 10%"
          type = "float"
        },
        {
          name = "instance @ 50%"
          type = "float"
        },
        {
          name = "instance @ 100%"
          type = "float"
        },
        {
          name = "hardware information on aws documentation & comments"
          type = "string"
        }
      ]
    }
  ]
}

module "glue_table_from_csv" {
  source   = "./modules/smd_glue_table_from_csv"
  for_each = { for f in local.static_csv_files : f.table_name => f }

  glue_database_name = module.shared_storage.glue_database_name
  glue_table_name    = each.key

  s3_bucket_name    = module.shared_storage.raw_s3_bucket_name
  s3_table_location = "s3://${module.shared_storage.raw_s3_bucket_name}/${each.value.s3_prefix}"

  csv_files = [
    {
      local_path = "../data/${each.value.file_name}"
      s3_key     = "${each.value.s3_prefix}/${each.value.file_name}"
    }
  ]

  columns = each.value.columns
}

################################################################################
# S3 and Athena resources for Grafana
################################################################################

resource "aws_athena_workgroup" "this" {
  name = "sustainability-metrics-dashboard"

  configuration {
    #1GB
    bytes_scanned_cutoff_per_query     = 1073741824
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${aws_s3_bucket.grafana.id}/query-output/"

      encryption_configuration {
        encryption_option = "SSE_KMS"
        kms_key_arn       = module.shared_storage.kms_key_arn
      }
    }
  }

  tags = {
    "GrafanaDataSource" = "true"
  }
}

resource "aws_s3_bucket" "grafana" {
  # checkov:skip=CKV_AWS_144: This bucket does not need to be multi region. Implementation left to specific consumer environment.
  # checkov:skip=CKV_AWS_21: Versioning not enabled. Versioning not enabled, query results are short-lived.
  # checkov:skip=CKV_AWS_18: Bucket logging not enabled. Implementation left to specific consumer environment.
  bucket_prefix = "grafana-athena-query-results-"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "grafana" {
  bucket = aws_s3_bucket.grafana.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = module.shared_storage.kms_key_arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "grafana" {
  bucket                  = aws_s3_bucket.grafana.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


################################################################################
# Collect Resource Data Lambda - ec2_collect
################################################################################
data "aws_caller_identity" "current" {}

locals {
  ec2_scaling_table_prefix = "resource-data/scaling-data/resources"
  cost_tags                = ["cost_centre"]
  ec2_lambda_env_vars = {
    COST_TAGS                = jsonencode(local.cost_tags),
    BUCKET_NAME              = module.shared_storage.raw_s3_bucket_name,
    EC2_SCALING_TABLE_PREFIX = local.ec2_scaling_table_prefix,
  }
  workspace_name = "cloud_sustainability_dashboard"
}

module "ec2_lambda_collector" {
  source             = "./modules/lambda_collector"
  name               = "ec2_lambda_collector"
  handler            = "ec2_collect.handle"
  region             = var.region
  path               = "${path.root}/../collect-resource-data/.build"
  env_vars           = local.ec2_lambda_env_vars
  bucket_name        = module.shared_storage.raw_s3_bucket_name
  glue_database_name = var.glue_database_name
  kms_key_arn        = module.shared_storage.kms_key_arn
  s3_prefixes        = [local.ec2_scaling_table_prefix]
  glue_table_arns    = [aws_glue_catalog_table.ec2_scaling_table.arn]

  additional_iam_policies = [
    { name = "ReadEC2"
      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Action = [
              "ec2:List*",
              "ec2:Get*",
              "ec2:Describe*"
            ]
            Effect   = "Allow"
            Resource = "*"
          },
        ]
      })
    }
  ]
}

resource "aws_glue_catalog_table" "ec2_scaling_table" {
  name          = "ec2_scaling_data"
  database_name = module.shared_storage.glue_database_name
  table_type    = "EXTERNAL_TABLE"

  parameters = {
    EXTERNAL                 = "TRUE"
    "skip.header.line.count" = "1"
  }

  partition_keys {
    name = "date"
    type = "string"
  }

  storage_descriptor {
    input_format  = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"

    ser_de_info {
      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"

      parameters = {
        "serialization.format" = 1
      }
    }

    columns {
      name = "type"
      type = "string"
    }

    columns {
      name = "id"
      type = "string"
    }

    columns {
      name = "scale_to_zero"
      type = "boolean"
    }

    dynamic "columns" {
      for_each = local.cost_tags
      content {
        name = columns.value
        type = "string"
      }
    }

    location = "s3://${module.shared_storage.raw_s3_bucket_name}/${local.ec2_scaling_table_prefix}/"
  }
}

################################################################################
# Collect Resource Data Lambda - s3_collect
################################################################################

locals {
  s3_lifecycle_policy_table_prefix = "resource-data/s3-data/resources"
  s3_lambda_env_vars = {
    BUCKET_NAME                      = module.shared_storage.raw_s3_bucket_name,
    S3_LIFECYCLE_POLICY_TABLE_PREFIX = local.s3_lifecycle_policy_table_prefix
  }
}

module "s3_lambda_collector" {
  source             = "./modules/lambda_collector"
  name               = "s3_lambda_collector"
  handler            = "s3_collect.handle"
  region             = var.region
  path               = "${path.root}/../collect-resource-data/.build"
  env_vars           = local.s3_lambda_env_vars
  bucket_name        = module.shared_storage.raw_s3_bucket_name
  glue_database_name = var.glue_database_name
  kms_key_arn        = module.shared_storage.kms_key_arn
  s3_prefixes        = [local.s3_lifecycle_policy_table_prefix]
  glue_table_arns    = [aws_glue_catalog_table.s3_collector_table.arn]
  additional_iam_policies = [
    { name = "collect_bucket_data"
      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Action = [
              "s3:ListAllMyBuckets",
              "s3:GetLifecycleConfiguration"
            ]
            Effect   = "Allow"
            Resource = "*"
          },
        ]
      })
    }
  ]
}

resource "aws_glue_catalog_table" "s3_collector_table" {
  name          = "s3_data"
  database_name = module.shared_storage.glue_database_name
  table_type    = "EXTERNAL_TABLE"

  parameters = {
    EXTERNAL                 = "TRUE"
    "skip.header.line.count" = "1"
  }

  partition_keys {
    name = "date"
    type = "string"
  }

  storage_descriptor {
    input_format  = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"

    ser_de_info {
      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"

      parameters = {
        "serialization.format" = 1
      }
    }

    columns {
      name = "bucket_name"
      type = "string"
    }

    columns {
      name = "lifecycle_policy"
      type = "boolean"
    }

    location = "s3://${module.shared_storage.raw_s3_bucket_name}/${local.s3_lifecycle_policy_table_prefix}/"
  }
}

################################################################################
# Collect Resource Data Lambda - cloudwatch_collect
################################################################################

locals {
  cloudwatch_collect_table_prefix = "resource-data/cloudwatch-data/resources"
  cloudwatch_lambda_env_vars = {
    CW_CPU_METRICS_TABLE_PREFIX = local.cloudwatch_collect_table_prefix,
    BUCKET_NAME                 = module.shared_storage.raw_s3_bucket_name
  }
}

module "cloudwatch_lambda_collector" {
  source             = "./modules/lambda_collector"
  name               = "cloudwatch_lambda_collector"
  region             = var.region
  handler            = "cloudwatch_collect.handle"
  path               = "${path.root}/../collect-resource-data/.build"
  env_vars           = local.cloudwatch_lambda_env_vars
  bucket_name        = module.shared_storage.raw_s3_bucket_name
  glue_database_name = var.glue_database_name
  kms_key_arn        = module.shared_storage.kms_key_arn
  s3_prefixes        = [local.cloudwatch_collect_table_prefix]
  glue_table_arns    = [aws_glue_catalog_table.cloudwatch_collector_table.arn]
  additional_iam_policies = [
    { name = "cloudwatch_lambda_collector_specific",
      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Action = [
              "Cloudwatch:List*",
              "Cloudwatch:Get*",
              "Cloudwatch:Describe*",
              "ec2:DescribeInstances",
              "rds:DescribeDBInstances",
            ]
            Effect   = "Allow"
            Resource = "*"
          },
        ]
      })
    }
  ]
}

resource "aws_glue_catalog_table" "cloudwatch_collector_table" {
  name          = "cloudwatch_data"
  database_name = module.shared_storage.glue_database_name
  table_type    = "EXTERNAL_TABLE"

  parameters = {
    EXTERNAL                 = "TRUE"
    "skip.header.line.count" = "1"
  }

  partition_keys {
    name = "date"
    type = "string"
  }

  storage_descriptor {
    input_format  = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"

    ser_de_info {
      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"

      parameters = {
        "serialization.format" = 1
      }
    }

    columns {
      name = "instance_id"
      type = "string"
    }

    columns {
      name = "service"
      type = "string"
    }

    columns {
      name = "avg_cpu"
      type = "double"
    }

    columns {
      name = "max_cpu"
      type = "double"
    }

    columns {
      name = "min_cpu"
      type = "double"
    }
    location = "s3://${module.shared_storage.raw_s3_bucket_name}/${local.cloudwatch_collect_table_prefix}/"
  }
}

################################################################################
# Collect Resource Data Lambda - cloudwatch_collect
################################################################################

resource "aws_grafana_workspace" "cloud_sustainability_dashboard" {
  count                    = var.create_managed_grafana ? 1 : 0
  name                     = local.workspace_name
  account_access_type      = "CURRENT_ACCOUNT"
  authentication_providers = ["AWS_SSO"]
  permission_type          = "SERVICE_MANAGED"
  data_sources             = ["CLOUDWATCH", "ATHENA"]
  role_arn                 = aws_iam_role.dashboard_role[0].arn
  depends_on = [
    aws_iam_role.dashboard_role[0]
  ]
}

resource "aws_iam_role" "dashboard_role" {
  count = var.create_managed_grafana ? 1 : 0
  name  = "cloud_sustainability_dashboard-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "grafana.amazonaws.com"
        }
      },
    ]
  })
  inline_policy {
    name   = "grafana-sustainability-dash-pol"
    policy = data.aws_iam_policy_document.dashboard_policy_document.json
  }

}


data "aws_iam_policy_document" "dashboard_policy_document" {

  statement {
    sid       = "AllowReadingMetricsFromCloudWatch"
    effect    = "Allow"
    resources = ["*"]
    actions = [
      "cloudwatch:DescribeAlarmsForMetric",
      "cloudwatch:DescribeAlarmHistory",
      "cloudwatch:DescribeAlarms",
      "cloudwatch:ListMetrics",
      "cloudwatch:GetMetricStatistics",
      "cloudwatch:GetMetricData",
      "cloudwatch:GetInsightRuleReport",
    ]
  }

  statement {
    sid       = "AllowReadingTagsInstancesRegionsFromEC2"
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "ec2:DescribeTags",
      "ec2:DescribeInstances",
      "ec2:DescribeRegions",
    ]
  }

  statement {
    sid       = "AllowReadingResourcesForTags"
    effect    = "Allow"
    resources = ["*"]
    actions   = ["tag:GetResources"]
  }

  statement {
    sid       = ""
    effect    = "Allow"
    resources = [module.CUR_stack.database_arn, module.shared_storage.glue_database_arn]

    actions = [
      "athena:GetDatabase",
      "athena:GetDataCatalog",
      "athena:GetTableMetadata",
      "athena:ListTableMetadata",
    ]
  }

  statement {
    sid       = ""
    effect    = "Allow"
    resources = ["*"]
    actions = [
      "athena:ListDatabases",
      "athena:ListDataCatalogs",
    ]
  }


  statement {
    sid       = ""
    effect    = "Allow"
    resources = [aws_athena_workgroup.this.arn]

    actions = [
      "athena:GetQueryExecution",
      "athena:GetQueryResults",
      "athena:GetWorkGroup",
      "athena:StartQueryExecution",
      "athena:StopQueryExecution",
    ]
  }

  statement {
    sid       = ""
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "athena:ListWorkGroups",
    ]
  }


  statement {
    sid    = ""
    effect = "Allow"
    resources = [
      module.CUR_stack.database_arn,
      module.shared_storage.glue_database_arn,
      "arn:aws:glue:${var.region}:${data.aws_caller_identity.current.account_id}:catalog",
      "arn:aws:glue:${var.region}:${data.aws_caller_identity.current.account_id}:table/${module.shared_storage.glue_database_name}/*",
      "arn:aws:glue:${var.region}:${data.aws_caller_identity.current.account_id}:table/${module.CUR_stack.database_name}/*"
    ]

    actions = [
      "glue:GetDatabase",
      "glue:GetDatabases",
      "glue:GetTable",
      "glue:GetTables",
      "glue:GetPartition",
      "glue:GetPartitions",
      "glue:BatchGetPartition",
    ]
  }

  statement {
    sid       = ""
    effect    = "Allow"
    resources = [aws_s3_bucket.grafana.arn, "${aws_s3_bucket.grafana.arn}/*"]
    actions = [
      "s3:GetBucketLocation",
      "s3:PutObject",
      "s3:AbortMultipartUpload",
    ]
  }

  statement {
    sid    = ""
    effect = "Allow"

    resources = [
      aws_s3_bucket.grafana.arn,
      "${aws_s3_bucket.grafana.arn}/*",
      "arn:aws:s3:::${var.cur_s3_bucket_name}",
      "arn:aws:s3:::${var.cur_s3_bucket_name}/*",
      module.shared_storage.raw_s3_bucket_arn,
      "${module.shared_storage.raw_s3_bucket_arn}/*",
    ]
    actions = [
      "s3:GetObject",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:ListMultipartUploadParts",
      "s3:PutBucketPublicAccessBlock",
    ]
  }

  statement {
    sid    = ""
    effect = "Allow"

    resources = [module.shared_storage.kms_key_arn]

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:GenerateDataKey",
    ]
  }
}


# resource "aws_grafana_workspace_api_key" "admin_key" {
#   count = var.create_managed_grafana ? 1 : 0
#   key_name        = "automation-admin-key"
#   key_role        = "ADMIN"
#   seconds_to_live = var.grafana_api_key_ttl
#   workspace_id    = aws_grafana_workspace.cloud_sustainability_dashboard[0].id
#   depends_on = [
#     aws_grafana_workspace.cloud_sustainability_dashboard[0]
#   ]
# }

# resource "grafana_data_source" "athena" {
#   count = ( var.create_managed_grafana && var.create_grafana_datasources) ? 1 : 0
#   type = "grafana-athena-datasource"
#   name = "Amazon Athena - Sustainability Data"
#   depends_on = [
#     aws_grafana_workspace_api_key.admin_key
#   ]

#   json_data_encoded = jsonencode({
#     auth_type      = "default"
#     default_region = var.region
#     catalog        = "AwsDataCatalog"
#     database       = module.CUR_stack.database_name
#     workgroup      = aws_athena_workgroup.this.name
#   })
#   provider = grafana.grafana
# }

# resource "grafana_dashboard" "cloud-sustainability-dashboard" {
#   count = ( var.create_managed_grafana && var.create_grafana_datasources) ? 1 : 0
#   config_json = file("grafana-dashboard.json")
#   depends_on = [
#     grafana_data_source.athena,
#     grafana_data_source.test_db,
#     grafana_data_source.cloudwatch
#   ]
# }
