#!/bin/bash

AWS_PROFILE="selvam"
REGION="us-east-1"

echo "Creating ECR repositories..."

aws ecr create-repository --repository-name product-service --profile $AWS_PROFILE --region $REGION
aws ecr create-repository --repository-name order-service --profile $AWS_PROFILE --region $REGION

echo "ECR repositories created successfully!"