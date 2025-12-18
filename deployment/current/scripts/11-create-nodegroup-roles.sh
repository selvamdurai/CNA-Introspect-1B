#!/bin/bash
set -e

AWS_PROFILE="selvam"
ROLE_NAME="${1:-eks-nodegroup-role}"

echo "=== Creating NodeGroup IAM Role ==="
echo "Role Name: $ROLE_NAME"

# Create nodegroup role
echo "Creating IAM role $ROLE_NAME..."
aws iam create-role --role-name $ROLE_NAME --assume-role-policy-document '{
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
}' --profile $AWS_PROFILE || echo "Role $ROLE_NAME already exists"

# Attach required policies
echo "Attaching policies to $ROLE_NAME..."
aws iam attach-role-policy --role-name $ROLE_NAME --policy-arn arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy --profile $AWS_PROFILE
aws iam attach-role-policy --role-name $ROLE_NAME --policy-arn arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy --profile $AWS_PROFILE
aws iam attach-role-policy --role-name $ROLE_NAME --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly --profile $AWS_PROFILE

# Additional policies for enhanced functionality
aws iam attach-role-policy --role-name $ROLE_NAME --policy-arn arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy --profile $AWS_PROFILE
aws iam attach-role-policy --role-name $ROLE_NAME --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore --profile $AWS_PROFILE

echo "NodeGroup role $ROLE_NAME created and configured successfully!"
aws iam get-role --role-name $ROLE_NAME --profile $AWS_PROFILE --query 'Role.Arn' --output text