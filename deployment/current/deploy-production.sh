#!/bin/bash
set -e

echo "=== Production Deployment Pipeline ==="

# Make all scripts executable
chmod +x scripts/*.sh

# Production-ready deployment with all features
echo "Phase 1: Infrastructure Foundation"
./scripts/01-create-iam-roles.sh
./scripts/02-setup-ecr.sh

echo "Phase 2: Core Platform (Parallel)"
./scripts/03-build-push-images.sh &
BUILD_PID=$!
./scripts/04-create-eks-cluster.sh &
CLUSTER_PID=$!

wait $BUILD_PID && echo "✓ Images ready"
wait $CLUSTER_PID && echo "✓ Cluster ready"

echo "Phase 3: Platform Enhancement"
./scripts/09-install-eks-addons.sh
./scripts/19-enable-cloudwatch-logs.sh
./scripts/18-create-irsa.sh
./scripts/05-install-dapr.sh
./scripts/06-setup-sns-pubsub.sh

echo "Phase 4: Application Deployment"
./scripts/07-deploy-services.sh

echo "Phase 5: Monitoring & Management"
./scripts/15-install-k8s-dashboard.sh

echo "=== Production Deployment Complete! ==="
echo "Cluster Information:"
kubectl get nodes -o wide
echo ""
echo "Application Status:"
kubectl get pods,svc,ingress --all-namespaces
echo ""
echo "Dashboard Access:"
echo "1. Get token: kubectl -n kubernetes-dashboard create token admin-user"
echo "2. Start proxy: kubectl proxy"
echo "3. Open: http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/"