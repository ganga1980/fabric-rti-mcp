#!/bin/bash
# Build and push Docker image to Azure Container Registry

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Variables
ACR_NAME="${ACR_NAME:-youracr}"
IMAGE_NAME="${IMAGE_NAME:-fabric-rti-mcp}"
VERSION="${VERSION:-latest}"
DOCKERFILE_PATH="${DOCKERFILE_PATH:-./Dockerfile}"

# Check if ACR name is set
if [ "$ACR_NAME" = "youracr" ]; then
    print_error "Please set ACR_NAME environment variable"
    print_error "Example: export ACR_NAME=myacr"
    exit 1
fi

# Full image name
FULL_IMAGE_NAME="${ACR_NAME}.azurecr.io/${IMAGE_NAME}:${VERSION}"

print_info "Building Docker image: $FULL_IMAGE_NAME"

# Build the image
docker build -t "$FULL_IMAGE_NAME" -f "$DOCKERFILE_PATH" .

print_info "Logging in to Azure Container Registry..."
az acr login --name "$ACR_NAME"

print_info "Pushing image to ACR..."
docker push "$FULL_IMAGE_NAME"

print_info "Image pushed successfully: $FULL_IMAGE_NAME"

# Also tag as latest if this is a version tag
if [ "$VERSION" != "latest" ]; then
    LATEST_IMAGE="${ACR_NAME}.azurecr.io/${IMAGE_NAME}:latest"
    print_info "Tagging as latest: $LATEST_IMAGE"
    docker tag "$FULL_IMAGE_NAME" "$LATEST_IMAGE"
    docker push "$LATEST_IMAGE"
fi

print_info "Build and push complete!"
print_info "Image: $FULL_IMAGE_NAME"
