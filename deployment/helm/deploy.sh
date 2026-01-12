#!/bin/bash
set -e

# Helm Chart Validation and Deployment Script

CHART_DIR="./deployment/helm/fabric-rti-mcp"
NAMESPACE="${NAMESPACE:-fabric-rti-mcp}"
ENVIRONMENT="${ENVIRONMENT:-dev}"
RELEASE_NAME="${RELEASE_NAME:-fabric-rti-mcp}"

echo "==================================="
echo "Helm Chart Deployment Script"
echo "==================================="
echo "Environment: $ENVIRONMENT"
echo "Namespace: $NAMESPACE"
echo "Release Name: $RELEASE_NAME"
echo "==================================="

# Validate required environment variables
if [ -z "$IMAGE_REPOSITORY" ]; then
    echo "ERROR: IMAGE_REPOSITORY environment variable is required"
    exit 1
fi

if [ -z "$IMAGE_TAG" ]; then
    echo "ERROR: IMAGE_TAG environment variable is required"
    exit 1
fi

echo "Image: $IMAGE_REPOSITORY:$IMAGE_TAG"

# Lint the chart
echo ""
echo "Step 1: Linting Helm chart..."
helm lint $CHART_DIR --values $CHART_DIR/values-${ENVIRONMENT}.yaml

# Template and validate
echo ""
echo "Step 2: Validating chart templates..."
helm template $RELEASE_NAME $CHART_DIR \
  --namespace $NAMESPACE \
  --values $CHART_DIR/values-${ENVIRONMENT}.yaml \
  --set image.repository=$IMAGE_REPOSITORY \
  --set image.tag=$IMAGE_TAG \
  > /tmp/helm-template-output.yaml

echo "Template validation successful"

# Dry run
echo ""
echo "Step 3: Performing dry-run..."
helm upgrade --install $RELEASE_NAME $CHART_DIR \
  --namespace $NAMESPACE \
  --create-namespace \
  --values $CHART_DIR/values-${ENVIRONMENT}.yaml \
  --set image.repository=$IMAGE_REPOSITORY \
  --set image.tag=$IMAGE_TAG \
  --dry-run --debug

# Deploy
echo ""
echo "Step 4: Deploying to Kubernetes..."
helm upgrade --install $RELEASE_NAME $CHART_DIR \
  --namespace $NAMESPACE \
  --create-namespace \
  --values $CHART_DIR/values-${ENVIRONMENT}.yaml \
  --set image.repository=$IMAGE_REPOSITORY \
  --set image.tag=$IMAGE_TAG \
  --wait \
  --timeout 5m

echo ""
echo "==================================="
echo "Deployment completed successfully!"
echo "==================================="

# Show status
echo ""
echo "Release Status:"
helm status $RELEASE_NAME -n $NAMESPACE

echo ""
echo "Pods:"
kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=fabric-rti-mcp

echo ""
echo "Services:"
kubectl get svc -n $NAMESPACE -l app.kubernetes.io/name=fabric-rti-mcp

if [ "$ENVIRONMENT" != "dev" ]; then
    echo ""
    echo "Ingress:"
    kubectl get ingress -n $NAMESPACE -l app.kubernetes.io/name=fabric-rti-mcp
fi

echo ""
echo "==================================="
echo "To view logs, run:"
echo "kubectl logs -f -n $NAMESPACE -l app.kubernetes.io/name=fabric-rti-mcp"
echo "==================================="
