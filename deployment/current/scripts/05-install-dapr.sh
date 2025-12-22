#!/bin/bash
set -e

echo "=== Installing Dapr on EKS ==="

# Add Dapr Helm repo
helm repo add dapr https://dapr.github.io/helm-charts/
helm repo update

# Install Dapr with scheduler enabled so pub/sub components can persist jobs
DEFAULT_STORAGE_CLASS=${DAPR_STORAGE_CLASS:-gp2}

helm upgrade --install dapr dapr/dapr \
    --namespace dapr-system \
    --create-namespace \
    --set dapr_scheduler.enabled=true \
    --set dapr_scheduler.replicaCount=1 \
    --set dapr_scheduler.persistence.storageClassName=$DEFAULT_STORAGE_CLASS \
    --set dapr_placement.replicaCount=1 \
    --wait \
    --timeout 10m

echo "Dapr installed successfully!"

# Verify installation
kubectl get pods -n dapr-system