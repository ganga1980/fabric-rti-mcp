#!/bin/bash
# Setup script for Service Principal authentication (alternative auth method)
# Use this when workload identity is not available or for non-AKS deployments

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

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Variables
APP_NAME="${APP_NAME:-fabric-rti-mcp-sp}"
RESOURCE_GROUP="${RESOURCE_GROUP:-fabric-rti-mcp-rg}"
NAMESPACE="${NAMESPACE:-fabric-rti-mcp}"
SECRET_NAME="${SECRET_NAME:-fabric-rti-mcp-sp-secret}"

print_info "Creating service principal: $APP_NAME"
SP_OUTPUT=$(az ad sp create-for-rbac --name "$APP_NAME" --skip-assignment)

CLIENT_ID=$(echo "$SP_OUTPUT" | jq -r '.appId')
CLIENT_SECRET=$(echo "$SP_OUTPUT" | jq -r '.password')
TENANT_ID=$(echo "$SP_OUTPUT" | jq -r '.tenant')

print_info "Service Principal created successfully"
print_info "Client ID: $CLIENT_ID"
print_info "Tenant ID: $TENANT_ID"

print_warning "Client Secret (save this securely): $CLIENT_SECRET"

# Grant permissions (example - modify as needed)
print_warning "Please manually grant the service principal appropriate permissions to:"
print_warning "  1. Fabric workspaces"
print_warning "  2. Kusto clusters/databases"
print_warning "  3. Any other required resources"

# Create Kubernetes secret
print_info "Creating Kubernetes secret..."
kubectl create secret generic "$SECRET_NAME" \
    --from-literal=AZURE_CLIENT_ID="$CLIENT_ID" \
    --from-literal=AZURE_CLIENT_SECRET="$CLIENT_SECRET" \
    --from-literal=AZURE_TENANT_ID="$TENANT_ID" \
    --namespace="$NAMESPACE" \
    --dry-run=client -o yaml | kubectl apply -f -

print_info "========================================="
print_info "Service Principal Setup Complete!"
print_info "========================================="
print_info "Client ID: $CLIENT_ID"
print_info "Tenant ID: $TENANT_ID"
print_info "Secret created in namespace: $NAMESPACE"
print_info ""
print_info "Update your deployment to use the secret:"
print_info "  envFrom:"
print_info "  - secretRef:"
print_info "      name: $SECRET_NAME"
