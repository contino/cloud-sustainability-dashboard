"""
Collects daily data from AWS CloudWatch APIs and stores in S3.
This program collects CloudWatch compute statistics on a specific run.
"""
from datetime import datetime, timedelta, date, time
from typing import Dict, Any, List

import boto3
import pandas
import pandas as pd
from aws_lambda_powertools import Logger
from aws_lambda_powertools.utilities.typing import LambdaContext

import variables
from utils import write_df_to_s3_as_parquet, get_all_regions, add_partition
from variables import AWS_REGION, CW_CPU_METRICS_TABLE_PREFIX, GLUE_DATABASE, CW_CPU_METRICS_GLUE_TABLE

LOG = Logger()
S3 = boto3.client("s3", AWS_REGION)
YESTERDAY = date.today() - timedelta(days=1)
BUCKET_NAME = variables.BUCKET_NAME


def generate_ec2_cw_metrics(regions: List[str]) -> pandas.DataFrame:
    """
    Generates CloudWatch CPU Utilization metrics for EC2 instances.
    :return: Pandas dataframe with the data.
    """
    df = pd.DataFrame(columns=['date', 'instance_id', 'service', 'avg_cpu', 'max_cpu', 'min_cpu'])
    for region in regions:
        ec2_client = boto3.client('ec2', region)
        cw_client = boto3.client("cloudwatch", region)
        for instance_id in [instance['InstanceId']
                            for page in ec2_client.get_paginator('describe_instances').paginate()
                            for reservation in page['Reservations']
                            for instance in reservation['Instances']]:
            met = cw_client.get_metric_statistics(
                Namespace='AWS/EC2',
                MetricName='CPUUtilization',
                StartTime=datetime.combine(YESTERDAY, time.min),
                EndTime=datetime.combine(YESTERDAY, time.max),
                Period=86400,
                Statistics=['Average', 'Minimum', 'Maximum'],
                Unit='Percent',
                Dimensions=[{
                    'Name': 'InstanceId',
                    'Value': instance_id
                }]
            )['Datapoints']
            if met:
                df.loc[len(df)] = [YESTERDAY,
                                   instance_id,
                                   'AmazonEC2',
                                   met[0]['Average'],
                                   met[0]['Minimum'],
                                   met[0]['Maximum']]
            else:
                df.loc[len(df)] = [YESTERDAY, instance_id, 'AmazonEC2', 0, 0, 0]
    return df


def generate_rds_cw_metrics(regions: List[str]) -> pandas.DataFrame:
    """
    Generates CloudWatch CPU Utilization metrics for RDS instances.
    :return: Pandas dataframe with the data.
    """
    df = pd.DataFrame(columns=['date', 'instance_id', 'service', 'avg_cpu', 'max_cpu', 'min_cpu'])
    for region in regions:
        rds_client = boto3.client('rds', region)
        cw_client = boto3.client("cloudwatch", region)

        for instance_id in [instance['DBInstanceIdentifier']
                            for page in rds_client.get_paginator('describe_db_instances').paginate()
                            for instance in page['DBInstances']]:
            met = cw_client.get_metric_statistics(
                Namespace='AWS/RDS',
                MetricName='CPUUtilization',
                StartTime=datetime.combine(YESTERDAY, time.min),
                EndTime=datetime.combine(YESTERDAY, time.max),
                Period=86400,
                Statistics=['Average', 'Minimum', 'Maximum'],
                Unit='Percent',
                Dimensions=[{
                    'Name': 'DBInstanceIdentifier',
                    'Value': instance_id
                }]
            )['Datapoints']
            if met:
                df.loc[len(df)] = [YESTERDAY,
                                   instance_id,
                                   'AmazonRDS',
                                   met[0]['Average'],
                                   met[0]['Minimum'],
                                   met[0]['Maximum']]
            else:
                df.loc[len(df)] = [YESTERDAY, instance_id, 'AmazonRDS', 0, 0, 0]
    return df


def main() -> None:
    """
    Main function for both executing as AWS Lambda function or locally
    """
    LOG.info('Collecting CloudWatch data...')
    ec2_df = generate_ec2_cw_metrics(variables.AWS_REGIONS if variables.AWS_REGIONS else get_all_regions())
    LOG.info('CloudWatch data:\n%s', ec2_df.head())
    write_df_to_s3_as_parquet(ec2_df, BUCKET_NAME, CW_CPU_METRICS_TABLE_PREFIX, ['date'])
    add_partition(GLUE_DATABASE, CW_CPU_METRICS_GLUE_TABLE, date=str(YESTERDAY))

    rds_df = generate_rds_cw_metrics(variables.AWS_REGIONS if variables.AWS_REGIONS else get_all_regions())
    LOG.info('CloudWatch data:\n%s', rds_df.head())
    add_partition(GLUE_DATABASE, CW_CPU_METRICS_GLUE_TABLE, date=str(YESTERDAY))


@LOG.inject_lambda_context
def handle(event: Dict[str, Any], context: LambdaContext) -> Dict[str, Any]:
    """
    AWS Lambda handler for CloudWatch collection.
    :param event:   Lambda event.
    :param context: Lambda context.
    :return:        Empty object (discarded).
    """
    main()
    return {}


if __name__ == '__main__':
    main()
