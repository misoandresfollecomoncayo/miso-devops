#!/bin/bash

set -e

AWS_REGION="us-east-1"
AWS_ACCOUNT_ID="291935881445"
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
IMAGE_NAME="app-root"  # puedes renombrarlo a como quieres que se llame en ECR

echo "Building and pushing Docker image from project root to ECR..."

# Change to project root
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$PROJECT_ROOT"

echo ""
echo "Configuring ECR authentication..."
aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$ECR_REGISTRY"

echo ""
echo "Creating ECR repository (if it doesn't exist)..."
aws ecr create-repository --repository-name "$IMAGE_NAME" --region "$AWS_REGION" 2>/dev/null || echo "Repository $IMAGE_NAME already exists"

echo ""
echo "Building Docker image from project root (platform linux/amd64)..."
docker buildx build --platform linux/amd64 --no-cache -t "$IMAGE_NAME:latest" .

echo ""
echo "Tagging and pushing image to ECR..."
docker tag "$IMAGE_NAME:latest" "$ECR_REGISTRY/$IMAGE_NAME:latest"
docker push "$ECR_REGISTRY/$IMAGE_NAME:latest"

echo ""
echo "Cleaning local Docker images..."
docker rmi "$IMAGE_NAME:latest" "$ECR_REGISTRY/$IMAGE_NAME:latest" 2>/dev/null || echo "Image already cleaned"

echo ""
echo "Docker image process completed successfully!"
echo "Image available at: $ECR_REGISTRY/$IMAGE_NAME:latest"
