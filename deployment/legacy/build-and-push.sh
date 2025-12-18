#!/bin/bash

AWS_PROFILE="selvam"
REGION="us-east-1"
ACCOUNT_ID=$(aws sts get-caller-identity --profile $AWS_PROFILE --query Account --output text)

echo "Building and pushing Docker images..."

# Login to ECR
aws ecr get-login-password --profile $AWS_PROFILE --region $REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

# Build and push product service
cd services/product_service
docker build -t product-service .
docker tag product-service:latest $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/product-service:latest
docker push $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/product-service:latest

# Build and push order service
cd ../order_service
docker build -t order-service .
docker tag order-service:latest $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/order-service:latest
docker push $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/order-service:latest

cd ../..
echo "Images pushed successfully!"
echo "Product Service: $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/product-service:latest"
echo "Order Service: $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/order-service:latest"