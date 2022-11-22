import pytest

import ec2_collect as cut
import variables

tags_cost_centre = [{'Key': 'Name', 'Value': 'test-instance'},
                    {'Key': 'cost_centre', 'Value': '000000'},
                    {'Key': 'Environment', 'Value': 'dev'}]
tags_autoscaling = [{'Key': 'aws:autoscaling:groupName', 'Value': 'test'},
                    {'Key': 'eksctl.cluster.k8s.io/v1alpha1/cluster-name', 'Value': 'test'}]
tags_none = []
instance = {
    "AmiLaunchIndex": 0,
    "ImageId": "ami-0545ec18117c1a66d",
    "InstanceId": "i-03ef9c193ef90a450",
    "InstanceType": "p3.2xlarge",
    "KeyName": "testing",
}
instance_cost_centre = {
    **instance,
    "Tags": tags_cost_centre
}
instance_autoscaling = {
    **instance,
    "Tags": tags_autoscaling
}
instance_no_tags = {
    **instance
}


@pytest.mark.integration
def test_describe_instances():
    response = cut.describe_instances([variables.AWS_REGION])
    assert response is not None
    for instance_desc in response:
        assert 'InstanceId' in instance_desc


def test_generate_ec2_scaling_details_with_no_cost_tag():
    response = cut.generate_ec2_scaling_details([instance_cost_centre])
    assert response is not None
    assert response.shape == (1, 4)
    assert not response['scale_to_zero'][0]


def test_generate_ec2_scaling_details_with_cost_tag():
    cut.COST_TAGS = ['cost_centre']
    response = cut.generate_ec2_scaling_details([instance_cost_centre])
    assert response is not None
    assert response.shape == (1, 5)
    assert not response['scale_to_zero'][0]
    assert response['cost_centre'][0] == '000000'


def test_generate_ec2_scaling_details_with_cost_tag_but_no_tags():
    cut.COST_TAGS = ['cost_centre']
    response = cut.generate_ec2_scaling_details([instance_no_tags])
    assert response is not None
    assert response.shape == (1, 5)
    assert not response['scale_to_zero'][0]
    assert response['cost_centre'][0] is None


def test_generate_ec2_scaling_details_with_cost_tag_but_different_tags():
    cut.COST_TAGS = ['cost_centre']
    response = cut.generate_ec2_scaling_details([instance_autoscaling])
    assert response is not None
    assert response.shape == (1, 5)
    assert response['scale_to_zero'][0]
    assert response['cost_centre'][0] is None


def test_generate_ec2_scaling_details_with_cost_tag_with_and_without_tags():
    cut.COST_TAGS = ['cost_centre']
    response = cut.generate_ec2_scaling_details([instance_autoscaling, instance_no_tags, instance_cost_centre])
    assert response is not None
    assert response.shape == (3, 5)
    assert response['scale_to_zero'][0]
    assert response['cost_centre'][0] is None
    assert not response['scale_to_zero'][1]
    assert response['cost_centre'][2] is not None


def test_has_ec2_scaling_tags():
    assert cut.has_ec2_scaling_tags(tags_cost_centre) is False
    assert cut.has_ec2_scaling_tags(tags_autoscaling) is True
    assert cut.has_ec2_scaling_tags(tags_none) is False
