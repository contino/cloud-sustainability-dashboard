"""
Module responsible for loading environment variables for the application.
"""
import json
import os


# Logging level
LOG_LEVEL = os.environ.get('LOG_LEVEL', 'INFO')

# AWS Region where application is deployed
AWS_REGION = os.environ.get('AWS_REGION', 'eu-west-2')

# AWS Regions to be observed
AWS_REGIONS = json.loads(os.environ.get('AWS_REGIONS')) if 'AWS_REGIONS' in os.environ else []

# Cost allocation tags to be observed
COST_TAGS = json.loads(os.environ.get('COST_TAGS')) if 'COST_TAGS' in os.environ else []

# S3 Bucket for data landing
BUCKET_NAME = os.environ.get('BUCKET_NAME', 'sustainability-report-test')

# EC2 Scaling Resources table S3 prefix
EC2_SCALING_TABLE_PREFIX = os.environ.get('EC2_SCALING_TABLE_PREFIX', 'resource-data/scaling-data/resources')

# S3 Lifecycle Policy table S3 prefix
S3_LIFECYCLE_POLICY_TABLE_PREFIX = os.environ.get('S3_LIFECYCLE_POLICY_TABLE_PREFIX',
                                                  'resource-data/s3-lifecycle-policy')

# CloudWatch EC2 CPU metric statistics table S3 prefix
CW_CPU_METRICS_TABLE_PREFIX = os.environ.get('CW_CPU_METRICS_TABLE_PREFIX', 'resource-data/cw-cpu-metrics')

# Glue database name
GLUE_DATABASE = os.environ.get('GLUE_DATABASE', 'sustainability_metrics_dashboard_data')

# EC2 Scaling Resources Glue table mame
EC2_SCALING_GLUE_TABLE = os.environ.get('EC2_SCALING_GLUE_TABLE', 'ec2_scaling_data')

# S3 Lifecycle Policy Glue table mame
S3_LIFECYCLE_POLICY_GLUE_TABLE = os.environ.get('S3_LIFECYCLE_POLICY_GLUE_TABLE', 's3_data')

# CloudWatch EC2 CPU metric statistics Glue table mame
CW_CPU_METRICS_GLUE_TABLE = os.environ.get('CW_CPU_METRICS_GLUE_TABLE', 'cloudwatch_data')
