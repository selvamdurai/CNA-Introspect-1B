#!/bin/bash
set -e

AWS_PROFILE="selvam"
REGION="us-east-1"

echo "=== Setting up ECR repositories ==="

# Create ECR repositories
aws ecr create-repository --repository-name product-service --profile $AWS_PROFILE --region $REGION 2>/dev/null || echo "Repository product-service already exists"
aws ecr create-repository --repository-name order-service --profile $AWS_PROFILE --region $REGION 2>/dev/null || echo "Repository order-service already exists"

echo "ECR repositories ready!"