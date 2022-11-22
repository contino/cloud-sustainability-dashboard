import pytest

import s3_collect as cut
import boto3

from moto import mock_s3
from variables import AWS_REGION, BUCKET_NAME


@pytest.mark.integration
def test_generate_all_s3_bucket_lifecycle_policies():
    response = cut.generate_all_s3_bucket_lifecycle_policies()
    assert response is not None
    assert len(response.columns) == 3
    assert len(response) > 0


@mock_s3
def test_main():
    cut.S3 = boto3.client('s3', AWS_REGION)
    cut.S3.create_bucket(Bucket=BUCKET_NAME, CreateBucketConfiguration={
        'LocationConstraint': 'eu-west-1'
    })
    cut.add_partition = lambda database, table, **kwargs: None
    cut.main()
    response = cut.S3.list_objects(Bucket=BUCKET_NAME)['Contents']
    assert response is not None
    assert len(response) == 1
    assert 'resource-data/s3-lifecycle-policy/date=' in response[0]['Key']
