#!/bin/bash
set -e

AWS_PROFILE="selvam"
REGION="us-east-1"
ACCOUNT_ID=$(aws sts get-caller-identity --profile $AWS_PROFILE --query Account --output text)

echo "=== Deploying Dapr-enabled services ==="

# Update manifests with account ID
sed "s/ACCOUNT_ID/$ACCOUNT_ID/g" k8s/dapr-services.yaml > k8s/dapr-services-updated.yaml

# Deploy SNS pubsub component
kubectl apply -f k8s/sns-pubsub-component.yaml

# Deploy services
kubectl apply -f k8s/dapr-services-updated.yaml

echo "Services deployed successfully!"

# Check status
kubectl get pods
kubectl get components