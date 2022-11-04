import pytest

import cloudwatch_collect as cut
import boto3

from moto import mock_s3, mock_ec2, mock_cloudwatch, mock_rds
from variables import AWS_REGION, BUCKET_NAME


@pytest.mark.integration
def test_generate_ec2_cw_metrics():
    response = cut.generate_ec2_cw_metrics([AWS_REGION])
    assert response is not None
    assert len(response.columns) == 6
    assert len(response) > 0


@pytest.mark.integration
def test_generate_rds_cw_metrics():
    response = cut.generate_rds_cw_metrics([AWS_REGION])
    assert response is not None
    assert len(response.columns) == 6
    assert len(response) > 0


@mock_cloudwatch
@mock_ec2
@mock_s3
@mock_rds
def test_main():
    cut.S3 = boto3.client('s3', AWS_REGION)
    cut.S3.create_bucket(Bucket=BUCKET_NAME, CreateBucketConfiguration={
        'LocationConstraint': 'eu-west-1'
    })
    ec2 = boto3.resource('ec2', AWS_REGION)
    ec2.create_instances(ImageId='<ami-image-id>', MinCount=1, MaxCount=2)
    rds = boto3.client('rds', AWS_REGION)
    rds.create_db_instance(
        DBInstanceIdentifier="db-master-1",
        AllocatedStorage=10,
        Engine="postgres",
        DBName="staging-postgres",
        DBInstanceClass="db.m1.small",
        LicenseModel="license-included",
        MasterUsername="root",
        MasterUserPassword="hunter2",
        Port=1234,
        DBSecurityGroups=["my_sg"],
        VpcSecurityGroupIds=["sg-123456"],
        EnableCloudwatchLogsExports=["audit", "error"],
    )
    cut.add_partition = lambda database, table, **kwargs: None
    cut.main()
    response = cut.S3.list_objects(Bucket=BUCKET_NAME)['Contents']
    assert response is not None
    assert len(response) == 1
    assert 'resource-data/cw-cpu-metrics/date=' in response[0]['Key']
