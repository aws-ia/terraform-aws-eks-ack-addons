#!/bin/bash
# This job copies Sample data and pod templates to your S3 bucket which will enable you to run the Spark script

# Prerequisites for running this shell script
#     1/ Enter your S3 bucket below (<S3_BUCKET>) that "emr-data-team-a" service account IRSA can access.
#     2/ Enter region below (<REGION>). Same as the EKS Cluster region
#     3/ Execute the shell script which creates the input data in your S3 bucket

S3_BUCKET="sparkjob-demo-bucket"
REGION="us-west-2"       # Enter region


INPUT_DATA_S3_PATH="s3://${S3_BUCKET}/input/"
aws s3 cp spark-scripts-data/pod-templates/driver-pod-template.yaml s3://${S3_BUCKET}/scripts/ --region ${REGION}
aws s3 cp spark-scripts-data/pod-templates/executor-pod-template.yaml s3://${S3_BUCKET}/scripts/ --region ${REGION}

# Copy Test Input data to S3 bucket
mkdir input
wget https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2022-01.parquet -O "input/yellow_tripdata_2022-0.parquet"

# Making duplicate copies to increase the size of the data.
max=20
for (( i=1; i <= $max; ++i ))
do
    cp -rf "input/yellow_tripdata_2022-0.parquet" "input/yellow_tripdata_2022-${i}.parquet"
done

aws s3 sync "input/" ${INPUT_DATA_S3_PATH}
