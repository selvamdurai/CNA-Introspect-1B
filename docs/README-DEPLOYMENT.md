# Deployment Guide

## Prerequisites
- AWS CLI configured with `selvam` profile
- Docker installed
- kubectl installed
- Helm installed

## Quick Deploy
Run the complete pipeline:
```bash
./deploy-all.sh
```

## Individual Steps

### 1. Setup ECR Repositories
```bash
./scripts/01-setup-ecr.sh
```

### 2. Build and Push Docker Images
```bash
./scripts/02-build-push-images.sh
```

### 3. Create EKS Cluster
```bash
./scripts/03-create-eks-cluster.sh
```

### 4. Install Dapr
```bash
./scripts/04-install-dapr.sh
```

### 5. Setup AWS SNS/SQS
```bash
./scripts/05-setup-sns-pubsub.sh
```

### 6. Deploy Services
```bash
./scripts/06-deploy-services.sh
```

## Architecture
- **Product Service**: Dapr-enabled publisher (port 8001)
- **Order Service**: Dapr-enabled subscriber (port 8002)
- **Pub/Sub**: AWS SNS/SQS via Dapr component
- **Platform**: EKS cluster with Dapr runtime