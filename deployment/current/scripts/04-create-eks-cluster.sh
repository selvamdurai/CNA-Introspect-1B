#!/bin/bash
set -e

AWS_PROFILE="selvam"
REGION="us-east-1"
CLUSTER_NAME="cna-introspect-1b-eks"
ACCOUNT_ID=$(aws sts get-caller-identity --profile $AWS_PROFILE --query Account --output text)

echo "=== Creating EKS cluster ==="

# Get VPC and subnets
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=is-default,Values=true" --profile $AWS_PROFILE --region $REGION --query 'Vpcs[0].VpcId' --output text)
SUBNETS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --profile $AWS_PROFILE --region $REGION --query 'Subnets[0:3].SubnetId' --output text | tr '\t' ',')

echo "Using VPC: $VPC_ID"
echo "Using Subnets: $SUBNETS"

# IAM roles should already exist from script 01-create-iam-roles.sh

# Check if cluster exists
if aws eks describe-cluster --name $CLUSTER_NAME --profile $AWS_PROFILE --region $REGION >/dev/null 2>&1; then
    echo "Cluster $CLUSTER_NAME already exists"
else
    echo "Creating EKS cluster $CLUSTER_NAME..."
    
    # Create cluster
    aws eks create-cluster \
        --name $CLUSTER_NAME \
        --version 1.28 \
        --role-arn arn:aws:iam::$ACCOUNT_ID:role/eks-service-role \
        --resources-vpc-config subnetIds=$SUBNETS \
        --profile $AWS_PROFILE \
        --region $REGION
    
    echo "Waiting for cluster to be active..."
    aws eks wait cluster-active --name $CLUSTER_NAME --profile $AWS_PROFILE --region $REGION
    
    # Create node group
    echo "Creating node group..."
    aws eks create-nodegroup \
        --cluster-name $CLUSTER_NAME \
        --nodegroup-name worker-nodes \
        --node-role arn:aws:iam::$ACCOUNT_ID:role/eks-nodegroup-role \
        --subnets $(echo $SUBNETS | tr ',' ' ') \
        --instance-types t3.medium \
        --scaling-config minSize=1,maxSize=3,desiredSize=2 \
        --profile $AWS_PROFILE \
        --region $REGION
    
    echo "Waiting for node group to be active..."
    aws eks wait nodegroup-active --cluster-name $CLUSTER_NAME --nodegroup-name worker-nodes --profile $AWS_PROFILE --region $REGION
fi

# Update kubeconfig
aws eks update-kubeconfig --name $CLUSTER_NAME --profile $AWS_PROFILE --region $REGION

echo "EKS cluster ready!"