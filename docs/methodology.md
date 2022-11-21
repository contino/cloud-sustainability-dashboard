# Methodology

## Metrics Calculation

The metrics are designed to give a starting point for cloud customers to optimize usage on the cloud, which can be
refined and extended based on teh requirements and nature of the cloud environment. Clear and up-to-date methodology is
important to provide transparency and support future refinement. We welcome contributions and do not provide any
guarantees for accuracy.

## Sustainability Signals

### Number of Elastic Compute Resources

The number of elastic compute services. These services and features can be easily configured to dynamically scale down
in periods of low demand.

At the time of writing, the following resources are covered:

Elastic Resources:

* EC2 instances part of an AutoScaling Group.
* EC2 instances managed by a kubernetes cluster autoscaler.

Non-Elastic Resources

* All other EC2 instances.

Data is sourced from AWS EC2 API.

### S3 Lifecycle Policies

The number of S3 buckets which have S3 lifecycle Configuration associated. Data is sourced from AWS S3 API.

## Instance Types & Physical Processors

It presents a tabular and a timeseries view of the amount of daily usage (vCPU hours) of EC2 instances (including 
instances used by other services such as RDS and Neptune) by physical processor type.

### Spot Instances
Shows the daily number of vCPU hours of on-demand, reserved, savings plan and spot instances. Only includes EC2 service.

## Utilization Metrics

### Maximum EC2 CPU Utilization 

Shows the maximum CPU utilization in a 6-hour period for selected EC2 instances. Sourced from CloudWatch.

### Maximum RDS CPU Utilization

Shows the maximum CPU utilization in a 6-hour period for selected RDS instances. Sourced from CloudWatch.

### ELBs unused for 7 days

Lists the Elastic Load Balancers that haven't received traffic but have been running for at least 7 days as determined
by line items in the AWS Cost and Usage Report.

## Total Usage Data

### Number of Resources per Region

Counts the number of resources in each region as counted by the number of distinct resource IDs for each region in the
AWS Cost and Usage Report.

## Carbon Emission & Energy Data

###  Grid Carbon Intensity per Region

Carbon Intensity (gCO₂eq/kWh) of the electricity grid where the AWS region is located. For most regions this is a 
12-month historical view ending in 12 months from September 2022 from https://app.electricitymaps.com/. For some regions
data is sourced from https://www.cloudcarbonfootprint.org/docs/methodology#appendix-v-grid-emissions-factors.
