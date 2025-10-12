#!/bin/bash

set -e

AWS_REGION="us-east-1"
AWS_ACCOUNT_ID="637423393351"
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

#APPS=("authsidecar_app" "offers_app" "posts_app" "rf003_app" "rf004_app" "rf005_app" "routes_app" "scores_app" "users_app" "consumer_app" "rf006_app")
APPS=("rf006_app")
#APPS=("users_app")

echo "Building and pushing Docker images to ECR..."

# Change to project root
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$PROJECT_ROOT"

# Get EKS cluster name and update kubeconfig
echo "Updating kubeconfig for EKS..."
if [[ -d "terraform/stacks/eks" ]]; then
    eks_cluster_id=$(cd terraform/stacks/eks && terraform output -raw eks_cluster_id 2>/dev/null || echo "")
    if [[ -n "$eks_cluster_id" ]]; then
        aws eks update-kubeconfig --region "$AWS_REGION" --name "$eks_cluster_id"
        echo "Connected to cluster: $(kubectl config current-context)"
    fi
fi

echo ""
echo "Configuring ECR authentication..."
aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$ECR_REGISTRY"

echo ""
echo "Creating ECR repositories (if they don't exist)..."
for app in "${APPS[@]}"; do
    echo "Creating repository: $app"
    aws ecr create-repository --repository-name "$app" --region "$AWS_REGION" 2>/dev/null || echo "Repository $app already exists"
done

echo ""
echo "Building Docker images for platform linux/amd64..."
for app in "${APPS[@]}"; do
    if [[ -d "./$app" ]]; then
        echo "Building $app..."
        docker buildx build --platform linux/amd64 --no-cache -t "$app:latest99" "./$app"
    else
        echo "Warning: Directory ./$app not found, skipping..."
    fi
done

echo ""
echo "Tagging and pushing images to ECR..."
for app in "${APPS[@]}"; do
    if docker images -q "$app:latest99" &>/dev/null; then
        echo "Processing $app..."
        docker tag "$app:latest99" "$ECR_REGISTRY/$app:latest99"
        docker push "$ECR_REGISTRY/$app:latest99"
        echo "Pushed $app successfully"
    else
        echo "Warning: Image $app:latest not found, skipping..."
    fi
done

echo ""
echo "Cleaning up local Docker images..."
for app in "${APPS[@]}"; do
    docker rmi "$app:latest99" "$ECR_REGISTRY/$app:latest99" 2>/dev/null || echo "Image $app already cleaned"
done

echo ""
echo "Docker image process completed successfully!"
echo "All images are now available in ECR at: $ECR_REGISTRY"
