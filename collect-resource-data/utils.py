"""
Module holding serialisation and AWS API utilities.
"""
import logging
from typing import List

import awswrangler as wr
import boto3
import pandas as pd

from variables import AWS_REGION

LOG = logging.getLogger(__name__)
GLUE = boto3.client('glue', AWS_REGION)


def write_df_to_s3_as_parquet(df: pd.DataFrame, bucket_name: str, bucket_prefix: str, partitions: List[str]) -> None:
    """
    Writes a Pandas DataFrame into a S3 bucket as Parquet under specified prefix.
    :param df:              the Pandas DataFrame
    :param bucket_name:     the S3 bucket name
    :param bucket_prefix:   the S3 key prefix
    :param partitions:      columns to partition by
    """
    data_path = f's3://{bucket_name}/{bucket_prefix}'
    LOG.info('Uploading resource data to %s', data_path)
    wr.s3.to_parquet(
        df=df,
        path=data_path,
        dataset=True,
        partition_cols=partitions,
        mode="overwrite_partitions"
    )


def get_all_regions() -> List[str]:
    """ Gets all AWS region names. """
    ec2_client = boto3.client('ec2', AWS_REGION)
    return [region['RegionName'] for region in ec2_client.describe_regions()['Regions']]


def add_partition(database: str, table: str, **kwargs: str) -> None:
    """
    Adds a partition to a Glue Catalog table.
    :param database:    the database name.
    :param table:       the table name.
    :param kwargs:      key and value for each partition key.
    """
    partition_input = _generate_partition_input(_get_table_storage_descriptor(database, table), **kwargs)
    try:
        response = GLUE.create_partition(
            DatabaseName=database,
            TableName=table,
            PartitionInput=partition_input
        )
        LOG.info('Partition added successfully: %s', response)
    except Exception:
        LOG.exception('Failure adding partitions to AWS Glue Catalog.')
        raise


def _get_table_storage_descriptor(database: str, table: str) -> dict:
    """
    Gets a Glue table storage description dictionary.
    :param database:    the database name.
    :param table:       the table name.
    :return:            the table storage description dictionary.
    """
    try:
        response = GLUE.get_table(
            DatabaseName=database,
            Name=table
        )
        return {
            'input_format': response['Table']['StorageDescriptor']['InputFormat'],
            'output_format': response['Table']['StorageDescriptor']['OutputFormat'],
            'table_location': response['Table']['StorageDescriptor']['Location'],
            'serde_info': response['Table']['StorageDescriptor']['SerdeInfo'],
            'partition_keys': [partition['Name'] for partition in response['Table']['PartitionKeys']]
        }
    except Exception:
        LOG.exception('Failure retrieving table information from AWS Glue Catalog.')
        raise


def _generate_partition_input(table_data: dict, **kwargs: str) -> dict:
    """
    Generates Glue partition input dictionary.
    :param table_data:  the table storage description dictionary.
    :param kwargs:      key and value for each partition key.
    :return:            the partition input dictionary.
    """
    partitions = '/'.join(f'{partition}={kwargs.get(partition)}' for partition in table_data.get('partition_keys'))
    part_location = f"{table_data['table_location']}{partitions}/"
    return {
        'Values': [kwargs.get(partition) for partition in table_data.get('partition_keys')],
        'StorageDescriptor': {
            'Location': part_location,
            'InputFormat': table_data['input_format'],
            'OutputFormat': table_data['output_format'],
            'SerdeInfo': table_data['serde_info']
        }
    }
