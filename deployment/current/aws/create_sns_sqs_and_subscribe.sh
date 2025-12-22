#!/usr/bin/env bash
set -euo pipefail

# Script to create SNS topic, SQS queues, set SQS policies and subscribe queues to topic.
# Uses AWS_PROFILE=selvam. Region defaults to us-east-1 - adjust if needed.

export AWS_PROFILE=selvam
REGION=${AWS_REGION:-us-east-1}
TOPIC_NAME=orders
Q1_NAME=product-service
Q2_NAME=order-service

echo "Region: $REGION"

echo "Creating SNS topic $TOPIC_NAME..."
TOPIC_ARN=$(aws sns create-topic --name "$TOPIC_NAME" --region "$REGION" --query 'TopicArn' --output text)
echo "TOPIC_ARN=$TOPIC_ARN"

create_queue() {
  QNAME=$1
  echo "Creating SQS queue $QNAME..."
  QURL=$(aws sqs create-queue --queue-name "$QNAME" --region "$REGION" --attributes VisibilityTimeout=30 --query 'QueueUrl' --output text)
  QARN=$(aws sqs get-queue-attributes --queue-url "$QURL" --region "$REGION" --attribute-names QueueArn --query 'Attributes.QueueArn' --output text)
  echo "$QNAME URL=$QURL ARN=$QARN"
  echo "$QURL" > /tmp/${QNAME}_url
  echo "$QARN" > /tmp/${QNAME}_arn
}

create_queue "$Q1_NAME"
create_queue "$Q2_NAME"

Q1_URL=$(cat /tmp/${Q1_NAME}_url)
Q1_ARN=$(cat /tmp/${Q1_NAME}_arn)
Q2_URL=$(cat /tmp/${Q2_NAME}_url)
Q2_ARN=$(cat /tmp/${Q2_NAME}_arn)

# Set queue policy to allow SNS topic to send messages
set_policy() {
  QURL=$1
  QARN=$2
  POLICY=$(cat <<EOF
{
  "Version":"2012-10-17",
  "Id":"Allow-SNS-SendMessage",
  "Statement":[
    {
      "Sid":"Allow-SNS-SendMessage",
      "Effect":"Allow",
      "Principal":{"Service":"sns.amazonaws.com"},
      "Action":"sqs:SendMessage",
      "Resource":"$QARN",
      "Condition":{"ArnEquals":{"aws:SourceArn":"$TOPIC_ARN"}}
    }
  ]
}
EOF
)
  echo "Setting policy on $QARN"
  aws sqs set-queue-attributes --queue-url "$QURL" --region "$REGION" --attributes Policy="$POLICY"
}

set_policy "$Q1_URL" "$Q1_ARN"
set_policy "$Q2_URL" "$Q2_ARN"

# Subscribe queues to topic (SQS subscriptions for SNS)
echo "Subscribing $Q1_ARN to $TOPIC_ARN"
SUB1=$(aws sns subscribe --topic-arn "$TOPIC_ARN" --protocol sqs --notification-endpoint "$Q1_ARN" --region "$REGION" --attributes RawMessageDelivery=true --query 'SubscriptionArn' --output text)
echo "Subscription1=$SUB1"
echo "Subscribing $Q2_ARN to $TOPIC_ARN"
SUB2=$(aws sns subscribe --topic-arn "$TOPIC_ARN" --protocol sqs --notification-endpoint "$Q2_ARN" --region "$REGION" --attributes RawMessageDelivery=true --query 'SubscriptionArn' --output text)
echo "Subscription2=$SUB2"

echo "Done. Topic: $TOPIC_ARN, Queues: $Q1_ARN $Q2_ARN"

echo "$TOPIC_ARN" > /tmp/created_topic_arn
echo "$Q1_ARN" > /tmp/created_${Q1_NAME}_arn
echo "$Q2_ARN" > /tmp/created_${Q2_NAME}_arn

echo "Wrote ARNs to /tmp for later reference."
