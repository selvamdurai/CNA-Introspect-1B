#!/bin/bash
set -e

echo "=== Installing Dapr on EKS ==="

# Add Dapr Helm repo
helm repo add dapr https://dapr.github.io/helm-charts/
helm repo update

# Install Dapr
helm upgrade --install dapr dapr/dapr \
    --namespace dapr-system \
    --create-namespace \
    --wait

echo "Dapr installed successfully!"

# Verify installation
kubectl get pods -n dapr-system