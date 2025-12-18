#!/bin/bash
set -e

AWS_PROFILE="selvam"
REGION="us-east-1"

echo "=== Setting up AWS SNS for Dapr Pub/Sub ==="

# Create SNS topic
TOPIC_ARN=$(aws sns create-topic --name orders-topic --profile $AWS_PROFILE --region $REGION --query TopicArn --output text)
echo "Created SNS topic: $TOPIC_ARN"

# Create SQS queue for subscription
QUEUE_URL=$(aws sqs create-queue --queue-name orders-queue --profile $AWS_PROFILE --region $REGION --query QueueUrl --output text)
QUEUE_ARN=$(aws sqs get-queue-attributes --queue-url $QUEUE_URL --attribute-names QueueArn --profile $AWS_PROFILE --region $REGION --query Attributes.QueueArn --output text)
echo "Created SQS queue: $QUEUE_ARN"

# Subscribe SQS to SNS
aws sns subscribe --topic-arn $TOPIC_ARN --protocol sqs --notification-endpoint $QUEUE_ARN --profile $AWS_PROFILE --region $REGION

echo "SNS/SQS setup complete!"
echo "Topic ARN: $TOPIC_ARN"
echo "Queue ARN: $QUEUE_ARN"