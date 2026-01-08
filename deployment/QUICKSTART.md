# Quick Deployment Guide

This guide gets you up and running quickly with the Fabric RTI MCP Server on AKS.

## Prerequisites

- Azure subscription
- Azure CLI installed and logged in
- kubectl installed
- Docker installed (for building images)

## 5-Minute Setup

### 1. Set Environment Variables

```bash
export RESOURCE_GROUP="fabric-rti-mcp-rg"
export LOCATION="eastus"
export AKS_CLUSTER_NAME="fabric-rti-mcp-aks"
export ACR_NAME="fabricrtimcp"  # Must be globally unique
export MANAGED_IDENTITY_NAME="fabric-rti-mcp-identity"
```

### 2. Create Azure Resources

```bash
# Create resource group
az group create --name $RESOURCE_GROUP --location $LOCATION

# Create ACR
az acr create --resource-group $RESOURCE_GROUP --name $ACR_NAME --sku Standard

# Create AKS cluster with workload identity enabled
az aks create \
  --resource-group $RESOURCE_GROUP \
  --name $AKS_CLUSTER_NAME \
  --node-count 2 \
  --enable-addons monitoring \
  --enable-oidc-issuer \
  --enable-workload-identity \
  --attach-acr $ACR_NAME \
  --generate-ssh-keys
```

### 3. Build and Push Image

```bash
# Navigate to project root
cd fabric-rti-mcp

# Build and push Docker image
chmod +x deployment/scripts/build-and-push.sh
./deployment/scripts/build-and-push.sh
```

### 4. Setup Workload Identity

```bash
chmod +x deployment/scripts/setup-workload-identity.sh
./deployment/scripts/setup-workload-identity.sh
```

Save the **Managed Identity Client ID** from the output.

### 5. Grant Permissions

Replace the placeholders and run:

```bash
# Get managed identity principal ID
MANAGED_IDENTITY_PRINCIPAL_ID=$(az identity show \
  --name $MANAGED_IDENTITY_NAME \
  --resource-group $RESOURCE_GROUP \
  --query principalId -o tsv)

# Grant permissions to your Kusto cluster
az role assignment create \
  --assignee "$MANAGED_IDENTITY_PRINCIPAL_ID" \
  --role "Contributor" \
  --scope "/subscriptions/{subscription-id}/resourceGroups/{rg}/providers/Microsoft.Kusto/clusters/{cluster}"
```

### 6. Update Image References

```bash
# Update Kustomize files with your ACR name
find deployment/kubernetes -name "kustomization.yaml" -exec \
  sed -i "s/your-acr.azurecr.io/${ACR_NAME}.azurecr.io/g" {} \;
```

### 7. Deploy

```bash
# Get AKS credentials
az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_CLUSTER_NAME

# Deploy to dev environment
kubectl apply -k deployment/kubernetes/overlays/dev

# Wait for pods to be ready
kubectl wait --for=condition=ready pod \
  -l app.kubernetes.io/name=fabric-rti-mcp \
  -n fabric-rti-mcp-dev \
  --timeout=300s
```

### 8. Verify

```bash
# Check pods
kubectl get pods -n fabric-rti-mcp-dev

# Check health endpoint
kubectl port-forward -n fabric-rti-mcp-dev svc/fabric-rti-mcp-dev 8080:80 &
curl http://localhost:8080/health

# View logs
kubectl logs -n fabric-rti-mcp-dev -l app.kubernetes.io/name=fabric-rti-mcp
```

## Next Steps

- Configure ingress for external access (see [main README](README.md#ingress-configuration))
- Set up monitoring and alerts
- Deploy to staging/production environments
- Configure custom Kusto clusters in ConfigMap

## Troubleshooting

### Pods not starting?

```bash
kubectl describe pod -n fabric-rti-mcp-dev <pod-name>
kubectl logs -n fabric-rti-mcp-dev <pod-name>
```

### Authentication errors?

```bash
# Verify workload identity setup
kubectl get serviceaccount fabric-rti-mcp -n fabric-rti-mcp-dev -o yaml

# Check federated credential
az identity federated-credential list \
  --identity-name $MANAGED_IDENTITY_NAME \
  --resource-group $RESOURCE_GROUP
```

### Can't pull image?

```bash
# Verify ACR is attached to AKS
az aks check-acr --name $AKS_CLUSTER_NAME --resource-group $RESOURCE_GROUP --acr ${ACR_NAME}.azurecr.io

# List images in ACR
az acr repository show-tags --name $ACR_NAME --repository fabric-rti-mcp
```

## Clean Up

To delete all resources:

```bash
az group delete --name $RESOURCE_GROUP --yes --no-wait
```

For more detailed information, see the [main deployment README](README.md).
