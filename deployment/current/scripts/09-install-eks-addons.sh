#!/bin/bash
set -e

AWS_PROFILE="selvam"
REGION="us-east-1"
CLUSTER_NAME="cna-introspect-eks"
EBS_SA_NAME="ebs-csi-controller-sa"
DEFAULT_STORAGE_CLASS=${DEFAULT_STORAGE_CLASS:-gp2}

echo "=== Installing EKS Add-ons ==="

install_or_verify_addon() {
    local addon=$1
    echo "Ensuring addon '$addon' is installed..."
    if ! aws eks describe-addon --cluster-name $CLUSTER_NAME --addon-name $addon --profile $AWS_PROFILE --region $REGION >/dev/null 2>&1; then
        aws eks create-addon \
            --cluster-name $CLUSTER_NAME \
            --addon-name $addon \
            --profile $AWS_PROFILE \
            --region $REGION || echo "Addon $addon already being created"
    else
        echo "Addon $addon already exists"
    fi

    echo "Waiting for $addon addon to become ACTIVE..."
    aws eks wait addon-active --cluster-name $CLUSTER_NAME --addon-name $addon --profile $AWS_PROFILE --region $REGION || true
}

install_or_verify_addon amazon-cloudwatch-observability
install_or_verify_addon eks-pod-identity-agent
install_or_verify_addon metrics-server

echo "Configuring IAM service account for AWS EBS CSI driver..."
eksctl create iamserviceaccount \
    --name $EBS_SA_NAME \
    --namespace kube-system \
    --cluster $CLUSTER_NAME \
    --attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
    --approve \
    --override-existing-serviceaccounts \
    --region $REGION \
    --profile $AWS_PROFILE

echo "Installing AWS EBS CSI driver..."
helm repo add aws-ebs-csi-driver https://kubernetes-sigs.github.io/aws-ebs-csi-driver >/dev/null 2>&1 || true
helm repo update >/dev/null
helm upgrade --install aws-ebs-csi-driver aws-ebs-csi-driver/aws-ebs-csi-driver \
    --namespace kube-system \
    --set controller.serviceAccount.create=false \
    --set controller.serviceAccount.name=$EBS_SA_NAME \
    --wait

echo "Setting default storage class to '$DEFAULT_STORAGE_CLASS'..."
if kubectl get storageclass $DEFAULT_STORAGE_CLASS >/dev/null 2>&1; then
    kubectl patch storageclass $DEFAULT_STORAGE_CLASS -p '{"metadata": {"annotations": {"storageclass.kubernetes.io/is-default-class": "true"}}}' >/dev/null
    for sc in $(kubectl get storageclass -o jsonpath='{.items[*].metadata.name}'); do
        if [ "$sc" != "$DEFAULT_STORAGE_CLASS" ]; then
            kubectl patch storageclass $sc -p '{"metadata": {"annotations": {"storageclass.kubernetes.io/is-default-class": "false"}}}' >/dev/null || true
        fi
    done
else
    echo "StorageClass $DEFAULT_STORAGE_CLASS not found; skipping default assignment"
fi

echo "EKS Add-ons installation complete!"
kubectl get pods -n amazon-cloudwatch || true
kubectl get pods -n kube-system | grep -E "metrics-server|ebs-csi" || true
kubectl get storageclass