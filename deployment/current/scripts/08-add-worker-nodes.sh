#!/bin/bash
set -e

AWS_PROFILE="selvam"
REGION="us-east-1"
CLUSTER_NAME="cna-introspect-1b-eks"
ACCOUNT_ID=$(aws sts get-caller-identity --profile $AWS_PROFILE --query Account --output text)

echo "=== Adding worker nodes to EKS cluster ==="

# Get cluster VPC
CLUSTER_VPC=$(aws eks describe-cluster --name $CLUSTER_NAME --profile $AWS_PROFILE --region $REGION --query 'cluster.resourcesVpcConfig.vpcId' --output text)
echo "Cluster VPC: $CLUSTER_VPC"

# Get cluster subnets
SUBNETS=$(aws eks describe-cluster --name $CLUSTER_NAME --profile $AWS_PROFILE --region $REGION --query 'cluster.resourcesVpcConfig.subnetIds' --output text | tr '\t' ' ')
echo "Cluster Subnets: $SUBNETS"

# Create node group role if not exists
echo "Creating node group role..."
aws iam create-role --role-name eks-nodegroup-role --assume-role-policy-document '{
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
}' --profile $AWS_PROFILE 2>/dev/null || echo "Node group role already exists"

# Attach required policies
aws iam attach-role-policy --role-name eks-nodegroup-role --policy-arn arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy --profile $AWS_PROFILE 2>/dev/null || true
aws iam attach-role-policy --role-name eks-nodegroup-role --policy-arn arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy --profile $AWS_PROFILE 2>/dev/null || true
aws iam attach-role-policy --role-name eks-nodegroup-role --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly --profile $AWS_PROFILE 2>/dev/null || true

# Wait for role propagation
echo "Waiting for IAM role to propagate..."
sleep 15

# Create node group
echo "Creating node group..."
aws eks create-nodegroup \
    --cluster-name $CLUSTER_NAME \
    --nodegroup-name worker-nodes \
    --node-role arn:aws:iam::$ACCOUNT_ID:role/eks-nodegroup-role \
    --subnets $SUBNETS \
    --instance-types t3.medium \
    --scaling-config minSize=1,maxSize=3,desiredSize=2 \
    --profile $AWS_PROFILE \
    --region $REGION

echo "Waiting for node group to be active..."
aws eks wait nodegroup-active --cluster-name $CLUSTER_NAME --nodegroup-name worker-nodes --profile $AWS_PROFILE --region $REGION

echo "Worker nodes added successfully!"
kubectl get nodes