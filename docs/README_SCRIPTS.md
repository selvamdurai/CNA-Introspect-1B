Scripts for building, pushing and local scaffolding

Usage
- Create ECR repos (if missing):
  AWS_PROFILE=selvam ./scripts/create_ecr_repos.sh

- Build and push Docker images to ECR:
  AWS_PROFILE=selvam AWS_REGION=us-east-1 ./scripts/build_and_push_ecr.sh

- Setup local dev environment (virtualenv + install deps):
  ./scripts/setup_dev_env.sh

Notes
- Scripts default to using AWS profile `selvam` and region `us-east-1`. Override with environment variables.
