#!/bin/bash
# Setup script for AKS Workload Identity
# This script creates the necessary Azure resources and configures workload identity for the MCP server

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if required tools are installed
check_prerequisites() {
    print_info "Checking prerequisites..."

    if ! command -v az &> /dev/null; then
        print_error "Azure CLI is not installed. Please install it first."
        exit 1
    fi

    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed. Please install it first."
        exit 1
    fi

    print_info "Prerequisites check passed."
}

# Variables - Update these with your values
RESOURCE_GROUP="${RESOURCE_GROUP:-fabric-rti-mcp-rg}"
LOCATION="${LOCATION:-eastus}"
AKS_CLUSTER_NAME="${AKS_CLUSTER_NAME:-fabric-rti-mcp-aks}"
MANAGED_IDENTITY_NAME="${MANAGED_IDENTITY_NAME:-fabric-rti-mcp-identity}"
NAMESPACE="${NAMESPACE:-fabric-rti-mcp}"
SERVICE_ACCOUNT_NAME="${SERVICE_ACCOUNT_NAME:-fabric-rti-mcp}"
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

print_info "Configuration:"
print_info "  Resource Group: $RESOURCE_GROUP"
print_info "  Location: $LOCATION"
print_info "  AKS Cluster: $AKS_CLUSTER_NAME"
print_info "  Managed Identity: $MANAGED_IDENTITY_NAME"
print_info "  Namespace: $NAMESPACE"
print_info "  Service Account: $SERVICE_ACCOUNT_NAME"
print_info "  Subscription: $SUBSCRIPTION_ID"

# Confirm before proceeding
read -p "Do you want to proceed with these settings? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_warning "Aborted by user."
    exit 0
fi

# Step 1: Enable OIDC issuer and workload identity on AKS cluster
print_info "Enabling OIDC issuer and workload identity on AKS cluster..."
az aks update \
    --resource-group "$RESOURCE_GROUP" \
    --name "$AKS_CLUSTER_NAME" \
    --enable-oidc-issuer \
    --enable-workload-identity

# Get OIDC issuer URL
OIDC_ISSUER=$(az aks show \
    --resource-group "$RESOURCE_GROUP" \
    --name "$AKS_CLUSTER_NAME" \
    --query "oidcIssuerProfile.issuerUrl" -o tsv)

print_info "OIDC Issuer URL: $OIDC_ISSUER"

# Step 2: Create user-assigned managed identity
print_info "Creating user-assigned managed identity..."
az identity create \
    --name "$MANAGED_IDENTITY_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --location "$LOCATION"

# Get managed identity details
MANAGED_IDENTITY_CLIENT_ID=$(az identity show \
    --name "$MANAGED_IDENTITY_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --query clientId -o tsv)

MANAGED_IDENTITY_OBJECT_ID=$(az identity show \
    --name "$MANAGED_IDENTITY_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --query principalId -o tsv)

print_info "Managed Identity Client ID: $MANAGED_IDENTITY_CLIENT_ID"
print_info "Managed Identity Object ID: $MANAGED_IDENTITY_OBJECT_ID"

# Step 3: Create federated identity credential
print_info "Creating federated identity credential..."
az identity federated-credential create \
    --name "fabric-rti-mcp-federated-credential" \
    --identity-name "$MANAGED_IDENTITY_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --issuer "$OIDC_ISSUER" \
    --subject "system:serviceaccount:${NAMESPACE}:${SERVICE_ACCOUNT_NAME}" \
    --audience "api://AzureADTokenExchange"

print_info "Federated identity credential created."

# Step 4: Grant permissions to managed identity
print_info "Granting permissions to managed identity..."

# Example: Grant Contributor role to a specific Fabric workspace or resource
# Uncomment and modify as needed
# FABRIC_WORKSPACE_ID="/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.Fabric/workspaces/your-workspace"
# az role assignment create \
#     --assignee "$MANAGED_IDENTITY_OBJECT_ID" \
#     --role "Contributor" \
#     --scope "$FABRIC_WORKSPACE_ID"

# Grant permissions for Kusto/Eventhouse access
print_warning "Please manually grant the managed identity appropriate permissions to:"
print_warning "  1. Fabric workspaces"
print_warning "  2. Kusto clusters/databases"
print_warning "  3. Any other required resources"

# Step 5: Update Kubernetes service account
print_info "Getting AKS credentials..."
az aks get-credentials \
    --resource-group "$RESOURCE_GROUP" \
    --name "$AKS_CLUSTER_NAME" \
    --overwrite-existing

print_info "Creating namespace if it doesn't exist..."
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

print_info "Updating service account with workload identity annotation..."
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: $SERVICE_ACCOUNT_NAME
  namespace: $NAMESPACE
  annotations:
    azure.workload.identity/client-id: $MANAGED_IDENTITY_CLIENT_ID
  labels:
    azure.workload.identity/use: "true"
EOF

print_info "Service account updated."

# Step 6: Update deployment to use workload identity
print_info "Updating deployment labels for workload identity..."
kubectl patch deployment fabric-rti-mcp \
    -n "$NAMESPACE" \
    --type=json \
    -p='[{"op": "add", "path": "/spec/template/metadata/labels/azure.workload.identity~1use", "value": "true"}]' \
    2>/dev/null || print_warning "Deployment not found. Apply manifests first."

# Output summary
print_info "========================================="
print_info "Workload Identity Setup Complete!"
print_info "========================================="
print_info ""
print_info "Configuration Details:"
print_info "  Managed Identity Client ID: $MANAGED_IDENTITY_CLIENT_ID"
print_info "  Managed Identity Object ID: $MANAGED_IDENTITY_OBJECT_ID"
print_info "  OIDC Issuer: $OIDC_ISSUER"
print_info ""
print_info "Next Steps:"
print_info "1. Grant the managed identity permissions to Fabric resources"
print_info "2. Update the configmap or deployment with any required environment variables"
print_info "3. Deploy the application: kubectl apply -k deployment/kubernetes/overlays/dev"
print_info ""
print_info "To verify the setup:"
print_info "  kubectl get serviceaccount $SERVICE_ACCOUNT_NAME -n $NAMESPACE -o yaml"
print_info "  kubectl get pods -n $NAMESPACE"
print_info ""
