#!/usr/bin/env bash
set -euo pipefail

AWS_PROFILE=${AWS_PROFILE:-selvam}
REGION=${AWS_REGION:-us-east-1}
ACCOUNT_ID=$(aws --profile "$AWS_PROFILE" sts get-caller-identity --query Account --output text)
PROD_REPO=${PROD_REPO:-cna-introspect-1b-product-service}
ORD_REPO=${ORD_REPO:-cna-introspect-1b-order-service}

BASE_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

echo "Profile=$AWS_PROFILE Region=$REGION Account=$ACCOUNT_ID"

# ensure repos
"$BASE_DIR/scripts/create_ecr_repos.sh"

echo "Logging in to ECR"
aws --profile "$AWS_PROFILE" --region "$REGION" ecr get-login-password | docker login --username AWS --password-stdin "$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com"

echo "Building product image"
docker build -t cna-introspect-product -f "$BASE_DIR/services/product_service/Dockerfile" "$BASE_DIR"
echo "Building order image"
docker build -t cna-introspect-order -f "$BASE_DIR/services/order_service/Dockerfile" "$BASE_DIR"

PROD_URI="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$PROD_REPO:latest"
ORD_URI="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$ORD_REPO:latest"

echo "Tagging images -> $PROD_URI, $ORD_URI"
docker tag cna-introspect-product:latest "$PROD_URI"
docker tag cna-introspect-order:latest "$ORD_URI"

echo "Pushing images to ECR"
docker push "$PROD_URI"
docker push "$ORD_URI"

echo "Done. Images pushed: $PROD_URI, $ORD_URI"
