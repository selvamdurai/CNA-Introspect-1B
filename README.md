# CNA-Introspect-1B Microservices

## Project Structure
```
├── services/           # Microservices source code
│   ├── product_service/
│   └── order_service/
├── deployment/         # Deployment configurations
│   ├── current/        # Active deployment scripts & manifests
│   └── legacy/         # Previous deployment files
├── docs/              # Documentation
├── buildspec.yml      # AWS CodeBuild configuration
└── requirements.txt   # Root dependencies
```

## Prerequisites
- AWS CLI configured with `selvam` profile
- Docker installed
- kubectl installed
- Helm installed
- eksctl installed (optional)

## Quick Start

### Development (Fast)
```bash
cd deployment/current
./deploy-fast.sh
```

### Complete Deployment
```bash
cd deployment/current
./deploy-all.sh
```

### Production Ready
```bash
cd deployment/current
./deploy-production.sh
```

## Deployment Steps

### Core Deployment (Automated)
1. **Create IAM Roles** - `01-create-iam-roles.sh`
2. **Setup ECR Repositories** - `02-setup-ecr.sh`
3. **Build & Push Images** - `03-build-push-images.sh`
4. **Create EKS Cluster** - `04-create-eks-cluster.sh`
5. **Install Dapr** - `05-install-dapr.sh`
6. **Setup SNS/SQS** - `06-setup-sns-pubsub.sh`
7. **Deploy Services** - `07-deploy-services.sh`
8. **Install EKS Add-ons** - `09-install-eks-addons.sh`

### Additional Management Scripts
- **Add Worker Nodes** - `08-add-worker-nodes.sh`
- **Add NodeGroup** - `10-add-nodegroup.sh [name] [instance-type] [size]`
- **Scale NodeGroup** - `12-scale-nodegroup.sh [name] [desired] [min] [max]`
- **Add Nodes** - `13-add-nodes.sh [nodegroup] [count]`
- **List Nodes** - `14-list-nodes.sh`
- **Install Dashboard** - `15-install-k8s-dashboard.sh`

## Services
- **ProductService**: FastAPI service (port 8001) - Dapr publisher
- **OrderService**: FastAPI service (port 8002) - Dapr subscriber

## Architecture
- **Platform**: Amazon EKS with managed node groups
- **Runtime**: Dapr for microservices communication
- **Messaging**: AWS SNS/SQS via Dapr pub/sub component
- **Monitoring**: CloudWatch Observability, Metrics Server
- **Registry**: Amazon ECR for container images

## Access
- **Pods**: Use `kubectl get pods --all-namespaces`
- **Nodes**: AWS Console → EKS → Cluster → Compute tab
- **Dashboard**: Run `15-install-k8s-dashboard.sh` then follow instructions