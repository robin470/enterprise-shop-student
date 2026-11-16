#!/bin/bash
set -euo pipefail

REGION=us-east-2
ACCOUNT=$(aws sts get-caller-identity --query Account --output text --region "$REGION")
REGISTRY=$ACCOUNT.dkr.ecr.$REGION.amazonaws.com
TAG=$(git rev-parse --short=7 HEAD)

aws ecr get-login-password --region "$REGION" |
docker login --username AWS --password-stdin "$REGISTRY"

for SERVICE in api-gateway user-service product-service order-service payment-service notification-service; do
  echo "Building $SERVICE for AMD64..."

  docker buildx build \
    --platform linux/amd64 \
    -f "services/$SERVICE/Dockerfile" \
    -t "$REGISTRY/enterprise-shop-$SERVICE:$TAG" \
    --push .
done

docker buildx build \
  --platform linux/amd64 \
  -f frontend/Dockerfile \
  -t "$REGISTRY/enterprise-shop-frontend:$TAG" \
  --push frontend

echo "All seven AMD64 images pushed successfully!"
echo "Image tag: $TAG"
