#!/bin/bash
set -e

AWS_PROFILE="selvam"
REGION="us-east-1"
CLUSTER_NAME="cna-introspect-eks"
NODEGROUP_NAME="${1:-additional-workers}"
INSTANCE_TYPE="${2:-t3.medium}"
DESIRED_SIZE="${3:-2}"

ACCOUNT_ID=$(aws sts get-caller-identity --profile $AWS_PROFILE --query Account --output text)

echo "=== Adding NodeGroup to EKS Cluster ==="
echo "NodeGroup: $NODEGROUP_NAME"
echo "Instance Type: $INSTANCE_TYPE"
echo "Desired Size: $DESIRED_SIZE"

# Get cluster subnets
SUBNETS=$(aws eks describe-cluster --name $CLUSTER_NAME --profile $AWS_PROFILE --region $REGION --query 'cluster.resourcesVpcConfig.subnetIds' --output text | tr '\t' ' ')
echo "Using Subnets: $SUBNETS"

# Create nodegroup role
echo "Creating nodegroup role..."
aws iam create-role --role-name eks-nodegroup-$NODEGROUP_NAME-role --assume-role-policy-document '{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}' --profile $AWS_PROFILE 2>/dev/null || echo "NodeGroup role already exists"

# Attach required policies
aws iam attach-role-policy --role-name eks-nodegroup-$NODEGROUP_NAME-role --policy-arn arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy --profile $AWS_PROFILE 2>/dev/null || true
aws iam attach-role-policy --role-name eks-nodegroup-$NODEGROUP_NAME-role --policy-arn arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy --profile $AWS_PROFILE 2>/dev/null || true
aws iam attach-role-policy --role-name eks-nodegroup-$NODEGROUP_NAME-role --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly --profile $AWS_PROFILE 2>/dev/null || true

# Wait for role propagation
echo "Waiting for IAM role to propagate..."
sleep 15

# Create nodegroup
echo "Creating nodegroup $NODEGROUP_NAME..."
aws eks create-nodegroup \
    --cluster-name $CLUSTER_NAME \
    --nodegroup-name $NODEGROUP_NAME \
    --node-role arn:aws:iam::$ACCOUNT_ID:role/eks-nodegroup-$NODEGROUP_NAME-role \
    --subnets $SUBNETS \
    --instance-types $INSTANCE_TYPE \
    --scaling-config minSize=1,maxSize=5,desiredSize=$DESIRED_SIZE \
    --profile $AWS_PROFILE \
    --region $REGION

echo "Waiting for nodegroup to be active..."
aws eks wait nodegroup-active --cluster-name $CLUSTER_NAME --nodegroup-name $NODEGROUP_NAME --profile $AWS_PROFILE --region $REGION

echo "NodeGroup $NODEGROUP_NAME added successfully!"
kubectl get nodes