#!/bin/bash
set -e

echo "=== Complete Deployment Pipeline ==="

# Make all scripts executable
chmod +x scripts/*.sh

# 1. Create IAM roles
echo "Step 1: Creating IAM roles..."
./scripts/01-create-iam-roles.sh

# 2. Setup ECR
echo "Step 2: Setting up ECR repositories..."
./scripts/02-setup-ecr.sh

# 3. Build and push images
echo "Step 3: Building and pushing Docker images..."
./scripts/03-build-push-images.sh

# 4. Create EKS cluster
echo "Step 4: Creating EKS cluster..."
./scripts/04-create-eks-cluster.sh

# 5. Install Dapr
echo "Step 5: Installing Dapr..."
./scripts/05-install-dapr.sh

# 6. Setup SNS/SQS
echo "Step 6: Setting up AWS SNS/SQS..."
./scripts/06-setup-sns-pubsub.sh

# 7. Install EKS Add-ons
echo "Step 7: Installing EKS Add-ons..."
./scripts/09-install-eks-addons.sh

# 8. Deploy services
echo "Step 8: Deploying services..."
./scripts/07-deploy-services.sh

echo "=== Deployment Complete! ==="