#!/bin/bash
set -e

AWS_PROFILE="selvam"
REGION="us-east-1"
CLUSTER_NAME="cna-introspect-1b-eks"
NODEGROUP_NAME="${1:-worker-nodes}"
ADD_COUNT="${2:-1}"

echo "=== Adding Nodes to EKS Cluster ==="
echo "NodeGroup: $NODEGROUP_NAME"
echo "Adding: $ADD_COUNT nodes"

# Get current scaling configuration
CURRENT_CONFIG=$(aws eks describe-nodegroup --cluster-name $CLUSTER_NAME --nodegroup-name $NODEGROUP_NAME --profile $AWS_PROFILE --region $REGION --query 'nodegroup.scalingConfig')
CURRENT_DESIRED=$(echo $CURRENT_CONFIG | jq -r '.desiredSize')
CURRENT_MAX=$(echo $CURRENT_CONFIG | jq -r '.maxSize')
CURRENT_MIN=$(echo $CURRENT_CONFIG | jq -r '.minSize')

NEW_DESIRED=$((CURRENT_DESIRED + ADD_COUNT))
NEW_MAX=$((CURRENT_MAX > NEW_DESIRED ? CURRENT_MAX : NEW_DESIRED))

echo "Current: Min=$CURRENT_MIN, Desired=$CURRENT_DESIRED, Max=$CURRENT_MAX"
echo "New: Min=$CURRENT_MIN, Desired=$NEW_DESIRED, Max=$NEW_MAX"

# Update nodegroup to add nodes
aws eks update-nodegroup-config \
    --cluster-name $CLUSTER_NAME \
    --nodegroup-name $NODEGROUP_NAME \
    --scaling-config minSize=$CURRENT_MIN,maxSize=$NEW_MAX,desiredSize=$NEW_DESIRED \
    --profile $AWS_PROFILE \
    --region $REGION

echo "Waiting for nodes to be added..."
aws eks wait nodegroup-active --cluster-name $CLUSTER_NAME --nodegroup-name $NODEGROUP_NAME --profile $AWS_PROFILE --region $REGION

echo "$ADD_COUNT nodes added to $NODEGROUP_NAME successfully!"
kubectl get nodes