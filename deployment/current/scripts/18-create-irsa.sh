#!/bin/bash
set -e

AWS_PROFILE="selvam"
REGION="us-east-1"
CLUSTER_NAME="cna-introspect-eks"
POLICY_NAME="DaprPubsubPolicy"
SERVICE_ACCOUNT_NAME="dapr-pubsub-sa"
NAMESPACE="default"

echo "=== Creating IRSA for Dapr pubsub ==="

echo "Ensure OIDC provider is associated with the cluster (eksctl)..."
eksctl utils associate-iam-oidc-provider --region $REGION --cluster $CLUSTER_NAME --approve --profile $AWS_PROFILE || echo "OIDC provider association may already exist"

echo "Writing temporary IAM policy document..."
cat > /tmp/dapr-pubsub-policy.json <<'EOF'
{
  "Version":"2012-10-17",
  "Statement":[
    {
      "Effect":"Allow",
      "Action":[
        "sns:CreateTopic",
        "sns:Subscribe",
        "sns:ListTopics",
        "sns:ListSubscriptions",
        "sns:ListSubscriptionsByTopic",
        "sns:GetTopicAttributes",
        "sns:Publish",
        "sns:TagResource",
        "sns:ListTagsForResource",
        "sqs:CreateQueue",
        "sqs:GetQueueUrl",
        "sqs:SendMessage",
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes",
        "sqs:SetQueueAttributes",
        "sqs:ListQueues",
        "sqs:ListQueueTags",
        "sqs:TagQueue",
        "sqs:UntagQueue"
      ],
      "Resource":"*"
    }
  ]
}
EOF

echo "Creating IAM policy $POLICY_NAME (if not exists)..."
aws iam create-policy --policy-name $POLICY_NAME --policy-document file:///tmp/dapr-pubsub-policy.json --profile $AWS_PROFILE 2>/dev/null || echo "Policy $POLICY_NAME already exists"

POLICY_ARN=$(aws iam list-policies --profile $AWS_PROFILE --query "Policies[?PolicyName=='$POLICY_NAME'].Arn" --output text)
if [ -z "$POLICY_ARN" ]; then
  echo "Failed to find policy ARN for $POLICY_NAME" >&2
  exit 1
fi

echo "Creating Kubernetes service account and attaching policy via eksctl..."
eksctl create iamserviceaccount \
  --name $SERVICE_ACCOUNT_NAME \
  --namespace $NAMESPACE \
  --cluster $CLUSTER_NAME \
  --attach-policy-arn $POLICY_ARN \
  --approve \
  --override-existing-serviceaccounts \
  --region $REGION \
  --profile $AWS_PROFILE

echo "IRSA setup complete. ServiceAccount: $NAMESPACE/$SERVICE_ACCOUNT_NAME attached to policy $POLICY_ARN"

echo "Cleaning up temporary policy file..."
rm -f /tmp/dapr-pubsub-policy.json

echo "Done."
