"""
Collects daily data from AWS S3 APIs and stores in S3. This program collect all S3 buckets and its respective lifecycle
policy status on a specific run.
"""
import datetime
from typing import Dict, Any

import boto3
import pandas
import pandas as pd
from aws_lambda_powertools import Logger
from aws_lambda_powertools.utilities.typing import LambdaContext
from botocore.exceptions import ClientError

import variables
from utils import write_df_to_s3_as_parquet, add_partition
from variables import AWS_REGION, S3_LIFECYCLE_POLICY_TABLE_PREFIX, GLUE_DATABASE, S3_LIFECYCLE_POLICY_GLUE_TABLE

LOG = Logger()
S3 = boto3.client('s3', AWS_REGION)
TODAY = datetime.date.today()
BUCKET_NAME = variables.BUCKET_NAME


def generate_all_s3_bucket_lifecycle_policies() -> pandas.DataFrame:
    """
    Generates S3 lifecycle policies status dataset.
    :return: Pandas dataframe with the data.
    """
    df = pd.DataFrame(columns=['date', 'bucket_name', 'lifecycle_policy'])
    for bucket in [bucket["Name"] for bucket in S3.list_buckets()["Buckets"]]:
        try:
            S3.get_bucket_lifecycle_configuration(Bucket=bucket)
            has_policy = True
        except ClientError as e:
            if e.response['Error']['Code'] != 'NoSuchLifecycleConfiguration':
                LOG.warning('It is not possible to assess bucket %s. Assuming no lifecycle policy: %s', bucket,
                            e.response['Error'])
            has_policy = False
        df.loc[len(df)] = [TODAY, bucket, has_policy]
    return df


def main() -> None:
    """
    Main function for both executing as AWS Lambda function or locally
    """
    LOG.info('Collecting S3 data...')
    df = generate_all_s3_bucket_lifecycle_policies()
    LOG.info('S3 data:\n%s', df.head())
    write_df_to_s3_as_parquet(df, BUCKET_NAME, S3_LIFECYCLE_POLICY_TABLE_PREFIX, ['date'])
    add_partition(GLUE_DATABASE, S3_LIFECYCLE_POLICY_GLUE_TABLE, date=str(TODAY))


@LOG.inject_lambda_context
def handle(event: Dict[str, Any], context: LambdaContext) -> Dict[str, Any]:
    """
    AWS Lambda handler for S3 collection.
    :param event:   Lambda event.
    :param context: Lambda context.
    :return:        Empty object (discarded).
    """
    main()
    return {}


if __name__ == '__main__':
    main()
