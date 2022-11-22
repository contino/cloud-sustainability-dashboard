import json

import utils as cut
import boto3
import pandas as pd

from moto import mock_s3, mock_ec2, mock_glue
from variables import AWS_REGION, BUCKET_NAME


@mock_s3
def test_write_df_to_s3_as_parquet():
    s3 = boto3.client("s3", AWS_REGION)
    s3.create_bucket(Bucket=BUCKET_NAME, CreateBucketConfiguration={
        'LocationConstraint': 'eu-west-1'
    })
    cut.write_df_to_s3_as_parquet(pd.DataFrame(data={'col1': ['val1'], 'col2': ['val2']}), BUCKET_NAME, 'prefix/', [])
    response = s3.list_objects(Bucket=BUCKET_NAME)['Contents']
    assert response is not None
    assert len(response) == 1
    assert 'prefix/' in response[0]['Key']


@mock_ec2
def test_get_all_regions():
    response = cut.get_all_regions()
    assert response is not None
    assert len(response) == 27
    assert 'eu-west-2' in response


@mock_glue
def test_add_partition():
    cut.GLUE = boto3.client('glue', AWS_REGION)
    cut.GLUE.create_database(DatabaseInput={
        'Name': 'database'
    })
    cut.GLUE.create_table(DatabaseName='database', TableInput={
        'Name': 'table',
        'StorageDescriptor': {
            'Location': 's3://bucket/table/',
            'InputFormat': 'org.apache.hadoop.hive.ql.io.avro.AvroContainerInputFormat',
            'OutputFormat': 'org.apache.hadoop.hive.ql.io.avro.AvroContainerOutputFormat',
            'SerdeInfo': {
                'SerializationLibrary': 'org.apache.hadoop.hive.serde2.avro.AvroSerDe',
                'Parameters': {
                    'DeserializationLibrary': 'org.apache.hadoop.hive.serde2.avro.AvroSerDe',
                },
            },
        },
        'PartitionKeys': [
            {
                'Name': 'part_one',
                'Type': 'string'
            },
            {
                'Name': 'part_two',
                'Type': 'string'
            }
        ],
        'TableType': 'EXTERNAL_TABLE'
    })
    assert not cut.GLUE.get_partitions(DatabaseName='database', TableName='table')['Partitions']
    cut.add_partition('database', 'table', part_two='two', part_one='one')
    print(json.dumps(cut.GLUE.get_partitions(DatabaseName='database', TableName='table'), indent=2, default=str))
    result = cut.GLUE.get_partitions(DatabaseName='database', TableName='table')['Partitions']
    assert result
    assert 'one' in result[0]['Values']
    assert 'two' in result[0]['Values']
    assert result[0]['StorageDescriptor']['Location'] == 's3://bucket/table/part_one=one/part_two=two/'
