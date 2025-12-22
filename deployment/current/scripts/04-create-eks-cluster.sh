#!/bin/bash
set -e

AWS_PROFILE="selvam"
REGION="us-east-1"
CLUSTER_NAME="cna-introspect-eks"

echo "=== Creating EKS cluster with eksctl ==="

# Delete existing cluster if it exists
echo "Cleaning up any existing cluster..."
eksctl delete cluster --name $CLUSTER_NAME --region $REGION --profile $AWS_PROFILE --wait 2>/dev/null || echo "No existing cluster to delete"

# Create cluster with eksctl (includes all necessary add-ons)
echo "Creating EKS cluster $CLUSTER_NAME..."
eksctl create cluster \
    --name $CLUSTER_NAME \
    --region $REGION \
    --nodegroup-name worker-nodes \
    --node-type t3.medium \
    --nodes 2 \
    --nodes-min 1 \
    --nodes-max 4 \
    --profile $AWS_PROFILE \
    --with-oidc \
    --ssh-access=false \
    --managed

echo "EKS cluster created successfully!"
kubectl get nodes