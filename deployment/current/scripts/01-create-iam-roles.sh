#!/bin/bash
set -e

AWS_PROFILE="selvam"
ACCOUNT_ID=$(aws sts get-caller-identity --profile $AWS_PROFILE --query Account --output text)

echo "=== Creating IAM Roles for EKS ==="

# Create EKS service role
echo "Creating EKS service role..."
aws iam create-role --role-name eks-service-role --assume-role-policy-document '{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}' --profile $AWS_PROFILE 2>/dev/null || echo "EKS service role already exists"

# Attach policies to EKS service role
aws iam attach-role-policy --role-name eks-service-role --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy --profile $AWS_PROFILE

# Create node group role
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

# Attach policies to node group role
aws iam attach-role-policy --role-name eks-nodegroup-role --policy-arn arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy --profile $AWS_PROFILE
aws iam attach-role-policy --role-name eks-nodegroup-role --policy-arn arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy --profile $AWS_PROFILE
aws iam attach-role-policy --role-name eks-nodegroup-role --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly --profile $AWS_PROFILE
aws iam attach-role-policy --role-name eks-nodegroup-role --policy-arn arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy --profile $AWS_PROFILE
aws iam attach-role-policy --role-name eks-nodegroup-role --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore --profile $AWS_PROFILE
aws iam attach-role-policy --role-name eks-nodegroup-role --policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy --profile $AWS_PROFILE

echo "Waiting for IAM roles to propagate..."
sleep 15

echo "IAM roles created successfully!"
echo "EKS Service Role: arn:aws:iam::$ACCOUNT_ID:role/eks-service-role"
echo "NodeGroup Role: arn:aws:iam::$ACCOUNT_ID:role/eks-nodegroup-role"