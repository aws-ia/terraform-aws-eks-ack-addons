

S3_BUCKET="sparkjob-demo-bucket"
REGION="us-west-2"       # Enter region


# Copy PySpark Script  to S3 bucket
aws s3 cp spark-scripts-data/pyspark-taxi-trip.py s3://${S3_BUCKET}/scripts/ --region ${REGION}
