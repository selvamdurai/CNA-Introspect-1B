#!/bin/bash
set -e

AWS_PROFILE="selvam"
REGION="us-east-1"
CLUSTER_NAME="cna-introspect-1b-eks"
NODEGROUP_NAME="${1:-worker-nodes}"
DESIRED_SIZE="${2:-3}"
MIN_SIZE="${3:-1}"
MAX_SIZE="${4:-5}"

echo "=== Scaling NodeGroup in EKS Cluster ==="
echo "NodeGroup: $NODEGROUP_NAME"
echo "Desired Size: $DESIRED_SIZE"
echo "Min Size: $MIN_SIZE"
echo "Max Size: $MAX_SIZE"

# Update nodegroup scaling configuration
echo "Updating nodegroup scaling configuration..."
aws eks update-nodegroup-config \
    --cluster-name $CLUSTER_NAME \
    --nodegroup-name $NODEGROUP_NAME \
    --scaling-config minSize=$MIN_SIZE,maxSize=$MAX_SIZE,desiredSize=$DESIRED_SIZE \
    --profile $AWS_PROFILE \
    --region $REGION

echo "Waiting for nodegroup update to complete..."
aws eks wait nodegroup-active --cluster-name $CLUSTER_NAME --nodegroup-name $NODEGROUP_NAME --profile $AWS_PROFILE --region $REGION

echo "NodeGroup $NODEGROUP_NAME scaled successfully!"
kubectl get nodes