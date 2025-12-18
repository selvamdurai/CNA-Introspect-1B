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

## Quick Start
```bash
cd deployment/current
./deploy-all.sh
```

## Services
- **ProductService**: FastAPI service (port 8001)
- **OrderService**: FastAPI service (port 8002)

Both services are Dapr-enabled with AWS SNS/SQS pub/sub messaging.