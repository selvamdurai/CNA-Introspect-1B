# Deployment Guide

## Prerequisites
- AWS CLI configured with `selvam` profile
- Docker installed
- kubectl installed
- Helm installed
- eksctl installed (optional)

## Quick Deploy
Run the complete pipeline:
```bash
./deploy-all.sh
```

## Individual Steps (Correct Order)

### 1. Create IAM Roles
```bash
./scripts/01-create-iam-roles.sh
```
Creates EKS service role and nodegroup role with all required policies.

### 2. Setup ECR Repositories
```bash
./scripts/02-setup-ecr.sh
```
Creates ECR repositories for product-service and order-service.

### 3. Build and Push Docker Images
```bash
./scripts/03-build-push-images.sh
```
Builds Docker images and pushes to ECR repositories.

### 4. Create EKS Cluster
```bash
./scripts/04-create-eks-cluster.sh
```
Creates EKS cluster and initial nodegroup using existing IAM roles.

### 5. Install EKS Add-ons
```bash
./scripts/09-install-eks-addons.sh
```
Installs CloudWatch Observability, Pod Identity Agent, Metrics Server, and the AWS EBS CSI driver.

### 6. Enable CloudWatch Log Shipping
```bash
./scripts/19-enable-cloudwatch-logs.sh
```
Creates/updates the CloudWatch log groups and Fluent Bit configuration so product-service, order-service, and Dapr logs flow into CloudWatch.

### 7. Install Dapr
```bash
./scripts/05-install-dapr.sh
```
Installs Dapr control plane on EKS cluster.

### 8. Setup AWS SNS/SQS
```bash
./scripts/06-setup-sns-pubsub.sh
```
Creates SNS topic and SQS queue for pub/sub messaging.

### 9. Deploy Services
```bash
./scripts/07-deploy-services.sh
```
Deploys Dapr-enabled microservices with pub/sub configuration.

## Management Scripts

### Add Worker Nodes
```bash
./scripts/08-add-worker-nodes.sh
```

### Add NodeGroup
```bash
./scripts/10-add-nodegroup.sh [name] [instance-type] [size]
```

### Scale NodeGroup
```bash
./scripts/12-scale-nodegroup.sh [name] [desired] [min] [max]
```

### Install Kubernetes Dashboard
```bash
./scripts/15-install-k8s-dashboard.sh
```

## Architecture
- **Product Service**: Dapr-enabled publisher (port 8001)
- **Order Service**: Dapr-enabled subscriber (port 8002)
- **Pub/Sub**: AWS SNS/SQS via Dapr component
- **Platform**: EKS cluster with Dapr runtime
- **Monitoring**: CloudWatch + Metrics Server
- **Registry**: Amazon ECR