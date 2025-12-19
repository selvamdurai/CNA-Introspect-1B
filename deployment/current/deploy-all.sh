#!/bin/bash
set -e

echo "=== Complete Deployment Pipeline ==="

# Make all scripts executable
chmod +x scripts/*.sh

# Phase 1: AWS Infrastructure Setup (Parallel-ready)
echo "Phase 1: AWS Infrastructure Setup"
echo "Step 1: Creating IAM roles..."
./scripts/01-create-iam-roles.sh

echo "Step 2: Setting up ECR repositories..."
./scripts/02-setup-ecr.sh

# Phase 2: Container Build & EKS Creation (Can run in parallel)
echo "Phase 2: Container & Cluster Preparation"
echo "Step 3: Building and pushing Docker images..."
./scripts/03-build-push-images.sh &
BUILD_PID=$!

echo "Step 4: Creating EKS cluster..."
./scripts/04-create-eks-cluster.sh &
CLUSTER_PID=$!

# Wait for both to complete
echo "Waiting for image build and cluster creation to complete..."
wait $BUILD_PID
echo "✓ Docker images ready"
wait $CLUSTER_PID
echo "✓ EKS cluster ready"

# Phase 3: Platform Setup (Sequential - depends on cluster)
echo "Phase 3: Platform Configuration"
echo "Step 5: Installing EKS Add-ons..."
./scripts/09-install-eks-addons.sh

echo "Step 6: Installing Dapr..."
./scripts/05-install-dapr.sh

echo "Step 7: Setting up AWS SNS/SQS..."
./scripts/06-setup-sns-pubsub.sh

# Phase 4: Application Deployment
echo "Phase 4: Application Deployment"
echo "Step 8: Deploying services..."
./scripts/07-deploy-services.sh

# Phase 5: Health Analysis
echo "Phase 5: AI-Powered Health Analysis"
echo "Waiting for services to stabilize..."
sleep 30
echo "Running log analysis..."
python3 scripts/17-enhanced-log-analyzer.py

echo "=== Deployment Complete! ==="
echo "Cluster Status:"
kubectl get nodes
echo "Services Status:"
kubectl get pods,svc