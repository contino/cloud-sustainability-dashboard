"""
Collects daily data from AWS EC2 APIs and stores in S3. This program describes AWS resources from their respective APIs,
categorizes and summarizes the data, and stores in S3.
"""
import datetime
from itertools import chain
from typing import List, Dict, Any

import boto3
import pandas as pd
from aws_lambda_powertools import Logger
from aws_lambda_powertools.utilities.typing import LambdaContext

import variables
from utils import write_df_to_s3_as_parquet, get_all_regions, add_partition
from variables import EC2_SCALING_TABLE_PREFIX, EC2_SCALING_GLUE_TABLE, GLUE_DATABASE

LOG = Logger()
TODAY = datetime.date.today()
BUCKET_NAME = variables.BUCKET_NAME
COST_TAGS = variables.COST_TAGS


def describe_instances(regions: List[str]) -> List[dict]:
    """
    Fetches EC2 'describe instances' data.
    :param regions: AWS regions being observed.
    :return:        List of AWS instance descriptions.
    """
    ec2_instances = list()
    for region in regions:
        ec2_client = boto3.client('ec2', region_name=region)
        LOG.info('Describing instances in region: %s', ec2_client.meta.region_name)
        paginator = ec2_client.get_paginator('describe_instances')
        page_iterator = paginator.paginate()
        ec2_instances = list(chain(
            ec2_instances,
            *[reservation['Instances'] for reservation in chain(*[page['Reservations'] for page in page_iterator])])
        )
    return ec2_instances


def generate_ec2_scaling_details(ec2_instances: List[dict]) -> pd.DataFrame:
    """
    Creates dataframe of scaling details from ec2 instance data.
    :param ec2_instances: List of EC2 instance descriptions
    :return:              Pandas data frame containing relevant data.
    """

    LOG.info('Calculating scaling details from ec2 instance data')
    scaling_data = [{
        'type': 'ec2',
        'id': instance.get('InstanceId'),
        'scale_to_zero': has_ec2_scaling_tags(instance.get('Tags', [])),
        **{tag_name: next(iter([tag['Value'] for tag in instance.get('Tags', []) if tag['Key'] == tag_name]),
                          None) for tag_name in COST_TAGS}
    } for instance in ec2_instances]

    df = pd.DataFrame(scaling_data)
    df.set_index('id')
    df['date'] = TODAY

    return df


def has_ec2_scaling_tags(tags_list: List[dict]) -> bool:
    """
    Tests if instance is autoscaling by checking presence of tags
    :param tags_list: The EC2 tag list.
    :return:          True or False.
    """

    autoscaling_keys = [
        'aws:autoscaling:groupName',
        'k8s.io/cluster-autoscaler/enabled'
    ]
    return any(x in [tag_pair['Key'] for tag_pair in tags_list]
               for x in autoscaling_keys)


def main() -> None:
    """
    Main function for both executing as AWS Lambda function or locally
    """
    LOG.info('Collecting EC2 data...')
    instances = describe_instances(variables.AWS_REGIONS if variables.AWS_REGIONS else get_all_regions())

    scaling_resource_df = generate_ec2_scaling_details(instances)
    write_df_to_s3_as_parquet(scaling_resource_df, BUCKET_NAME, EC2_SCALING_TABLE_PREFIX, ['date'])

    add_partition(GLUE_DATABASE, EC2_SCALING_GLUE_TABLE, date=str(TODAY))


@LOG.inject_lambda_context
def handle(event: Dict[str, Any], context: LambdaContext) -> Dict[str, Any]:
    """
    AWS Lambda handler for EC2 collection.
    :param event:   Lambda event.
    :param context: Lambda context.
    :return:        Empty object (discarded).
    """
    main()
    return {}


if __name__ == '__main__':
    main()
