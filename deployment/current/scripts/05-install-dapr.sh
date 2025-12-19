#!/bin/bash
set -e

echo "=== Installing Dapr on EKS ==="

# Add Dapr Helm repo
helm repo add dapr https://dapr.github.io/helm-charts/
helm repo update

# Install Dapr with minimal configuration (no scheduler)
helm upgrade --install dapr dapr/dapr \
    --namespace dapr-system \
    --create-namespace \
    --set dapr_scheduler.enabled=false \
    --set dapr_placement.replicaCount=1 \
    --timeout 10m

echo "Dapr installed successfully!"

# Verify installation
kubectl get pods -n dapr-system