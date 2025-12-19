#!/bin/bash
set -e

echo "=== Fast Deployment Pipeline ==="

# Make all scripts executable
chmod +x scripts/*.sh

# Quick setup for development
echo "Phase 1: Quick Infrastructure Setup"
./scripts/01-create-iam-roles.sh
./scripts/02-setup-ecr.sh

echo "Phase 2: Parallel Build & Cluster Creation"
# Start both processes in parallel
./scripts/03-build-push-images.sh &
./scripts/04-create-eks-cluster.sh &

# Wait for both to complete
wait

echo "Phase 3: Essential Platform Setup"
./scripts/05-install-dapr.sh
./scripts/07-deploy-services.sh

echo "=== Fast Deployment Complete! ==="
kubectl get pods,svc