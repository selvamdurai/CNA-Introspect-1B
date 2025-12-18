#!/usr/bin/env bash
set -euo pipefail

AWS_PROFILE=${AWS_PROFILE:-selvam}
REGION=${AWS_REGION:-us-east-1}
REPO_PRODUCT=${REPO_PRODUCT:-cna-introspect-1b-product-service}
REPO_ORDER=${REPO_ORDER:-cna-introspect-1b-order-service}

echo "Using AWS profile: $AWS_PROFILE, region: $REGION"

ensure_repo() {
  local repo=$1
  if aws --profile "$AWS_PROFILE" --region "$REGION" ecr describe-repositories --repository-names "$repo" >/dev/null 2>&1; then
    echo "ECR repository $repo already exists"
  else
    echo "Creating ECR repository: $repo"
    aws --profile "$AWS_PROFILE" --region "$REGION" ecr create-repository --repository-name "$repo" >/dev/null
    echo "Created $repo"
  fi
}

ensure_repo "$REPO_PRODUCT"
ensure_repo "$REPO_ORDER"

echo "ECR repositories ready: $REPO_PRODUCT, $REPO_ORDER"
