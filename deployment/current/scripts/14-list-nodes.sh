#!/bin/bash
set -e

AWS_PROFILE="selvam"
REGION="us-east-1"
CLUSTER_NAME="cna-introspect-1b-eks"

echo "=== EKS Cluster Node Information ==="

# List all nodegroups
echo "NodeGroups:"
aws eks list-nodegroups --cluster-name $CLUSTER_NAME --profile $AWS_PROFILE --region $REGION --output table

# Get detailed nodegroup information
NODEGROUPS=$(aws eks list-nodegroups --cluster-name $CLUSTER_NAME --profile $AWS_PROFILE --region $REGION --query 'nodegroups' --output text)

for ng in $NODEGROUPS; do
    echo ""
    echo "NodeGroup: $ng"
    aws eks describe-nodegroup --cluster-name $CLUSTER_NAME --nodegroup-name $ng --profile $AWS_PROFILE --region $REGION --query 'nodegroup.{Status:status,InstanceTypes:instanceTypes,ScalingConfig:scalingConfig,Health:health}' --output table
done

echo ""
echo "Kubernetes Nodes:"
kubectl get nodes -o wide