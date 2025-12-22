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
5. **Install EKS Add-ons & Storage** - `09-install-eks-addons.sh`
6. **Enable CloudWatch Log Shipping** - `19-enable-cloudwatch-logs.sh`
7. **Provision IRSA for Pub/Sub** - `18-create-irsa.sh`
8. **Install Dapr (with scheduler)** - `05-install-dapr.sh`
9. **Setup SNS/SQS** - `06-setup-sns-pubsub.sh`
10. **Deploy Services** - `07-deploy-services.sh`

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

## Bedrock Insights Helper
Use the Bedrock helper to generate Claude and Amazon Titan recommendations about the
deployment. The helper builds a structured prompt from project context and can run
offline (no AWS calls) for local testing.

```bash
source .venv/bin/activate              # if not already active
python -m tools.bedrock_insights.insights \
	--context-file docs/ARCHITECTURE.md  # any text/markdown file
```

Environment variables:

| Name | Purpose | Default |
| ---- | ------- | ------- |
| `BEDROCK_REGION` | Region used for the Bedrock `bedrock-runtime` client | `us-east-1` |
| `BEDROCK_CLAUDE_MODEL_ID` | Claude model identifier | `anthropic.claude-3-sonnet-20240229-v1:0` |
| `BEDROCK_TITAN_MODEL_ID` | Amazon Titan text model identifier | `amazon.titan-text-premier-v1:0` |

Add `--offline` to preview prompts without contacting AWS. The script outputs the
prompt plus each model's response so you can diff insights between providers.

## Architecture
- **Platform**: Amazon EKS with managed node groups
- **Runtime**: Dapr for microservices communication
- **Messaging**: AWS SNS/SQS via Dapr pub/sub component
- **Monitoring**: CloudWatch Observability, Metrics Server
- **Registry**: Amazon ECR for container images

See the full AWS architecture diagram in [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md), which renders the Mermaid diagram at [`docs/aws-architecture.mmd`](docs/aws-architecture.mmd).

## Access
- **Pods**: Use `kubectl get pods --all-namespaces`
- **Nodes**: AWS Console → EKS → Cluster → Compute tab
- **Dashboard**: Run `15-install-k8s-dashboard.sh` then follow instructions