#!/bin/bash
set -e

AWS_PROFILE="selvam"
REGION="us-east-1"
CLUSTER_NAME="cna-introspect-1b-eks"

echo "=== Installing EKS Add-ons ==="

# Install Amazon CloudWatch Observability
echo "Installing Amazon CloudWatch Observability..."
aws eks create-addon \
    --cluster-name $CLUSTER_NAME \
    --addon-name amazon-cloudwatch-observability \
    --profile $AWS_PROFILE \
    --region $REGION || echo "CloudWatch Observability addon already exists"

# Install Amazon EKS Pod Identity Agent
echo "Installing Amazon EKS Pod Identity Agent..."
aws eks create-addon \
    --cluster-name $CLUSTER_NAME \
    --addon-name eks-pod-identity-agent \
    --profile $AWS_PROFILE \
    --region $REGION || echo "Pod Identity Agent addon already exists"

# Install Metrics Server
echo "Installing Metrics Server..."
aws eks create-addon \
    --cluster-name $CLUSTER_NAME \
    --addon-name metrics-server \
    --profile $AWS_PROFILE \
    --region $REGION || echo "Metrics Server addon already exists"

# Install Fluent Bit
echo "Installing Fluent Bit..."
aws eks create-addon \
    --cluster-name $CLUSTER_NAME \
    --addon-name aws-for-fluent-bit \
    --profile $AWS_PROFILE \
    --region $REGION || echo "Fluent Bit addon already exists"

echo "Waiting for addons to be active..."
sleep 30

echo "EKS Add-ons installation complete!"
kubectl get pods -n amazon-cloudwatch
kubectl get pods -n kube-system | grep metrics-server