# Fabric RTI MCP Server - Deployment Guide

This guide provides comprehensive instructions for deploying the Fabric RTI MCP Server to Azure Kubernetes Service (AKS) with various authentication methods.

## Deployment Options

We offer **two deployment approaches**:

### 🎯 Helm Charts (Recommended)
**Easy configuration management with environment-specific values**
- ✅ Simple value overrides without editing files
- ✅ Built-in rollback capabilities
- ✅ Version tracking and release management
- ✅ Better environment management
- 📚 **[Get Started with Helm →](./helm/QUICKSTART.md)**

### 📋 Kustomize (Original)
**Patch-based overlay approach**
- Traditional Kubernetes YAML files
- Base + environment overlays
- Good for simple scenarios
- 📚 **[Continue with Kustomize →](#kustomize-deployment)**

## 🆕 Helm Chart Deployment

For the best experience with environment management and easy configuration, we recommend using Helm charts:

```bash
# Quick install for development
helm install fabric-rti-mcp ./helm/fabric-rti-mcp \
  --namespace fabric-rti-mcp-dev \
  --create-namespace \
  --values ./helm/fabric-rti-mcp/values-dev.yaml

# Quick install for production
helm install fabric-rti-mcp ./helm/fabric-rti-mcp \
  --namespace fabric-rti-mcp-prod \
  --create-namespace \
  --values ./helm/fabric-rti-mcp/values-prod.yaml
```

**📖 Complete Helm Documentation:**
- [Quick Start Guide](./helm/QUICKSTART.md)
- [Full Documentation](./helm/README.md)
- [Migration from Kustomize](./helm/MIGRATION.md)
- [Comparison Guide](./helm/COMPARISON.md)

---

## Kustomize Deployment

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Authentication Methods](#authentication-methods)
  - [Workload Identity (Recommended)](#workload-identity-recommended)
  - [Service Principal](#service-principal)
- [Deployment Options](#deployment-options)
- [Configuration](#configuration)
- [Monitoring and Troubleshooting](#monitoring-and-troubleshooting)
- [Security Best Practices](#security-best-practices)

## Overview

The Fabric RTI MCP Server runs as a containerized application in AKS, exposing MCP tools via HTTP/SSE transport. This deployment includes:

- **Production-ready Docker image** with security hardening
- **Kubernetes manifests** with health checks, resource limits, and auto-scaling
- **Multiple authentication methods** for Azure resources
- **Environment-specific configurations** (dev, staging, prod)
- **Ingress configuration** for external access
- **Monitoring integration** via health endpoints

## Prerequisites

### Required Tools

- **Azure CLI** (`az`) version 2.50.0 or later
- **kubectl** version 1.24 or later
- **Docker** (for building images)
- **kustomize** (optional, kubectl has it built-in)

Install Azure CLI:
```bash
# macOS
brew install azure-cli

# Linux
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Windows
# Download from https://aka.ms/installazurecliwindows
```

Install kubectl:
```bash
az aks install-cli
```

### Azure Resources

- **Azure subscription** with appropriate permissions
- **Azure Container Registry (ACR)** for storing images
- **AKS cluster** with the following features enabled:
  - OIDC issuer (for workload identity)
  - Workload identity addon
  - NGINX Ingress Controller or Azure Application Gateway (optional)

### Permissions Required

- Contributor or Owner on the resource group
- Permissions to create managed identities
- Permissions to create federated credentials
- Permissions to assign roles to managed identities

## Quick Start

### 1. Build and Push Docker Image

```bash
# Set your Azure Container Registry name
export ACR_NAME="your-acr-name"
export VERSION="v0.2.0"

# Build and push the image
cd fabric-rti-mcp
chmod +x deployment/scripts/build-and-push.sh
./deployment/scripts/build-and-push.sh
```

### 2. Setup Authentication (Workload Identity)

```bash
# Configure variables
export RESOURCE_GROUP="fabric-rti-mcp-rg"
export AKS_CLUSTER_NAME="fabric-rti-mcp-aks"
export LOCATION="eastus"

# Run the setup script
chmod +x deployment/scripts/setup-workload-identity.sh
./deployment/scripts/setup-workload-identity.sh
```

This script will:
- Enable OIDC issuer and workload identity on your AKS cluster
- Create a user-assigned managed identity
- Create a federated identity credential
- Configure the Kubernetes service account

### 3. Update Image References

Edit the kustomization files to point to your ACR:

```bash
# Update base kustomization
sed -i 's/your-acr.azurecr.io/YOUR_ACR_NAME.azurecr.io/g' \
  deployment/kubernetes/base/kustomization.yaml

# Update overlay kustomizations
for env in dev staging prod; do
  sed -i 's/your-acr.azurecr.io/YOUR_ACR_NAME.azurecr.io/g' \
    deployment/kubernetes/overlays/$env/kustomization.yaml
done
```

### 4. Deploy to Development

```bash
# Get AKS credentials
az aks get-credentials \
  --resource-group "$RESOURCE_GROUP" \
  --name "$AKS_CLUSTER_NAME"

# Deploy using kustomize
kubectl apply -k deployment/kubernetes/overlays/dev

# Check deployment status
kubectl get pods -n fabric-rti-mcp-dev
kubectl logs -n fabric-rti-mcp-dev -l app.kubernetes.io/name=fabric-rti-mcp
```

### 5. Verify Deployment

```bash
# Check pod status
kubectl get pods -n fabric-rti-mcp-dev

# Check service
kubectl get svc -n fabric-rti-mcp-dev

# Test health endpoint
kubectl port-forward -n fabric-rti-mcp-dev svc/fabric-rti-mcp-dev 8080:80
curl http://localhost:8080/health
```

## Authentication Methods

### Workload Identity (Recommended)

**Workload Identity** is the recommended authentication method for AKS. It uses OpenID Connect (OIDC) to exchange Kubernetes service account tokens for Azure AD tokens.

#### Advantages
- No secrets or credentials stored in Kubernetes
- Fine-grained access control per workload
- Automatic token rotation
- Better security posture

#### Setup

Run the automated setup script:

```bash
chmod +x deployment/scripts/setup-workload-identity.sh
export RESOURCE_GROUP="fabric-rti-mcp-rg"
export AKS_CLUSTER_NAME="fabric-rti-mcp-aks"
export LOCATION="eastus"
./deployment/scripts/setup-workload-identity.sh
```

#### Manual Setup

<details>
<summary>Click to expand manual setup steps</summary>

1. **Enable OIDC and Workload Identity on AKS:**
   ```bash
   az aks update \
     --resource-group "$RESOURCE_GROUP" \
     --name "$AKS_CLUSTER_NAME" \
     --enable-oidc-issuer \
     --enable-workload-identity
   ```

2. **Get OIDC Issuer URL:**
   ```bash
   export OIDC_ISSUER=$(az aks show \
     --resource-group "$RESOURCE_GROUP" \
     --name "$AKS_CLUSTER_NAME" \
     --query "oidcIssuerProfile.issuerUrl" -o tsv)
   ```

3. **Create Managed Identity:**
   ```bash
   az identity create \
     --name "fabric-rti-mcp-identity" \
     --resource-group "$RESOURCE_GROUP" \
     --location "$LOCATION"

   export MANAGED_IDENTITY_CLIENT_ID=$(az identity show \
     --name "fabric-rti-mcp-identity" \
     --resource-group "$RESOURCE_GROUP" \
     --query clientId -o tsv)
   ```

4. **Create Federated Credential:**
   ```bash
   az identity federated-credential create \
     --name "fabric-rti-mcp-federated-credential" \
     --identity-name "fabric-rti-mcp-identity" \
     --resource-group "$RESOURCE_GROUP" \
     --issuer "$OIDC_ISSUER" \
     --subject "system:serviceaccount:fabric-rti-mcp:fabric-rti-mcp" \
     --audience "api://AzureADTokenExchange"
   ```

5. **Update Service Account:**
   ```bash
   kubectl annotate serviceaccount fabric-rti-mcp \
     -n fabric-rti-mcp \
     azure.workload.identity/client-id="$MANAGED_IDENTITY_CLIENT_ID"

   kubectl label serviceaccount fabric-rti-mcp \
     -n fabric-rti-mcp \
     azure.workload.identity/use=true
   ```

6. **Update Deployment:**
   ```bash
   kubectl patch deployment fabric-rti-mcp \
     -n fabric-rti-mcp \
     --type=merge \
     -p='{"spec":{"template":{"metadata":{"labels":{"azure.workload.identity/use":"true"}}}}}'
   ```

</details>

#### Grant Permissions

Grant the managed identity permissions to access Fabric resources:

```bash
# Get managed identity principal ID
export MANAGED_IDENTITY_PRINCIPAL_ID=$(az identity show \
  --name "fabric-rti-mcp-identity" \
  --resource-group "$RESOURCE_GROUP" \
  --query principalId -o tsv)

# Grant permissions to Fabric workspace (example)
az role assignment create \
  --assignee "$MANAGED_IDENTITY_PRINCIPAL_ID" \
  --role "Contributor" \
  --scope "/subscriptions/{subscription-id}/resourceGroups/{rg}/providers/Microsoft.Fabric/workspaces/{workspace-name}"

# Grant permissions to Kusto cluster (example)
az role assignment create \
  --assignee "$MANAGED_IDENTITY_PRINCIPAL_ID" \
  --role "Azure Data Explorer Cluster All Database Admin" \
  --scope "/subscriptions/{subscription-id}/resourceGroups/{rg}/providers/Microsoft.Kusto/clusters/{cluster-name}"
```

### Service Principal

**Service Principal** authentication uses a client ID and secret for authentication.

#### Advantages
- Works in any Kubernetes environment (not AKS-specific)
- Simple to set up
- Compatible with non-Azure environments

#### Disadvantages
- Requires secret management
- Manual secret rotation
- Higher security risk

#### Setup

Run the automated setup script:

```bash
chmod +x deployment/scripts/setup-service-principal.sh
export APP_NAME="fabric-rti-mcp-sp"
export RESOURCE_GROUP="fabric-rti-mcp-rg"
export NAMESPACE="fabric-rti-mcp"
./deployment/scripts/setup-service-principal.sh
```

Save the client secret securely (e.g., in Azure Key Vault).

#### Manual Secret Creation

If you already have a service principal:

```bash
kubectl create secret generic fabric-rti-mcp-sp-secret \
  --from-literal=AZURE_CLIENT_ID="your-client-id" \
  --from-literal=AZURE_CLIENT_SECRET="your-client-secret" \
  --from-literal=AZURE_TENANT_ID="your-tenant-id" \
  --namespace="fabric-rti-mcp" \
  --dry-run=client -o yaml | kubectl apply -f -
```

Update the deployment to reference the secret:

```yaml
envFrom:
- secretRef:
    name: fabric-rti-mcp-sp-secret
```

## Deployment Options

### Using Kustomize

#### Development Environment

```bash
kubectl apply -k deployment/kubernetes/overlays/dev
```

Configuration:
- 1 replica
- Lower resource limits (128Mi-512Mi memory)
- Workload identity disabled by default

#### Staging Environment

```bash
kubectl apply -k deployment/kubernetes/overlays/staging
```

Configuration:
- 2 replicas
- Moderate resources (256Mi-768Mi memory)
- Workload identity enabled
- OBO flow enabled

#### Production Environment

```bash
kubectl apply -k deployment/kubernetes/overlays/prod
```

Configuration:
- 3+ replicas (autoscaling 3-20)
- Production resources (512Mi-2Gi memory)
- Workload identity enabled
- OBO flow enabled
- Pod anti-affinity rules
- Higher PDB requirements

### Using Helm (Alternative)

If you prefer Helm, you can convert the Kustomize manifests:

```bash
# Install Kustomize (if not already installed)
kubectl kustomize deployment/kubernetes/overlays/dev > dev-manifests.yaml

# Or use Helm template
helm template fabric-rti-mcp ./deployment/helm \
  --values ./deployment/helm/values-dev.yaml > dev-manifests.yaml

kubectl apply -f dev-manifests.yaml
```

## Configuration

### Environment Variables

Configure the MCP server using environment variables in the ConfigMap:

#### Core Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `FABRIC_RTI_TRANSPORT` | Transport protocol (`stdio` or `http`) | `http` |
| `FABRIC_RTI_HTTP_HOST` | HTTP server host | `0.0.0.0` |
| `FABRIC_RTI_HTTP_PORT` | HTTP server port | `3000` |
| `FABRIC_RTI_HTTP_PATH` | MCP endpoint path | `/mcp` |
| `FABRIC_RTI_STATELESS_HTTP` | Enable stateless HTTP mode | `true` |

#### Fabric API Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `FABRIC_API_BASE` | Fabric API base URL | `https://api.fabric.microsoft.com/v1` |
| `FABRIC_BASE_URL` | Fabric web UI base URL | `https://fabric.microsoft.com` |

#### Authentication Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `USE_OBO_FLOW` | Enable On-Behalf-Of token exchange | `false` |
| `FABRIC_RTI_MCP_AZURE_TENANT_ID` | Azure tenant ID | MS tenant |
| `FABRIC_RTI_MCP_ENTRA_APP_CLIENT_ID` | Entra app client ID (for OBO) | - |
| `FABRIC_RTI_MCP_USER_MANAGED_IDENTITY_CLIENT_ID` | UMI client ID (for OBO) | - |
| `FABRIC_RTI_MCP_KUSTO_AUDIENCE` | Kusto audience URL | `https://kusto.kusto.windows.net` |

#### Kusto Configuration (Optional)

| Variable | Description | Default |
|----------|-------------|---------|
| `KUSTO_SERVICE_URI` | Default Kusto cluster URI | - |
| `KUSTO_SERVICE_DEFAULT_DB` | Default database name | - |

### Updating Configuration

Edit the ConfigMap in your overlay:

```yaml
# deployment/kubernetes/overlays/dev/kustomization.yaml
configMapGenerator:
  - name: fabric-rti-mcp-config
    behavior: merge
    literals:
      - KUSTO_SERVICE_URI=https://your-cluster.kusto.windows.net
      - KUSTO_SERVICE_DEFAULT_DB=YourDatabase
```

Apply the changes:

```bash
kubectl apply -k deployment/kubernetes/overlays/dev
kubectl rollout restart deployment/fabric-rti-mcp-dev -n fabric-rti-mcp-dev
```

### Ingress Configuration

Update the ingress hostname in your overlay:

```yaml
patches:
  - target:
      kind: Ingress
      name: fabric-rti-mcp
    patch: |-
      - op: replace
        path: /spec/rules/0/host
        value: mcp.yourdomain.com
      - op: replace
        path: /spec/tls/0/hosts/0
        value: mcp.yourdomain.com
```

#### Using cert-manager for TLS

Install cert-manager and configure a ClusterIssuer:

```bash
# Install cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# Create ClusterIssuer
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: your-email@example.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
EOF
```

Update ingress annotation:

```yaml
metadata:
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
```

## Monitoring and Troubleshooting

### Health Checks

The server exposes a `/health` endpoint:

```bash
# From within the cluster
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- \
  curl http://fabric-rti-mcp.fabric-rti-mcp-dev.svc.cluster.local/health

# Via port-forward
kubectl port-forward -n fabric-rti-mcp-dev svc/fabric-rti-mcp-dev 8080:80
curl http://localhost:8080/health
```

Expected response:

```json
{
  "status": "healthy",
  "current_time_utc": "2026-01-07 12:00:00 UTC",
  "server": "fabric-rti-mcp",
  "start_time_utc": "2026-01-07 11:00:00 UTC"
}
```

### View Logs

```bash
# Get logs from all pods
kubectl logs -n fabric-rti-mcp-dev -l app.kubernetes.io/name=fabric-rti-mcp

# Follow logs in real-time
kubectl logs -n fabric-rti-mcp-dev -l app.kubernetes.io/name=fabric-rti-mcp -f

# Get logs from a specific pod
kubectl logs -n fabric-rti-mcp-dev fabric-rti-mcp-dev-xxxxx

# Get previous pod logs (if crashed)
kubectl logs -n fabric-rti-mcp-dev fabric-rti-mcp-dev-xxxxx --previous
```

### Common Issues

#### 1. Pods Not Starting

**Symptom:** Pods stuck in `ImagePullBackOff` or `CrashLoopBackOff`

**Solutions:**

```bash
# Check pod events
kubectl describe pod -n fabric-rti-mcp-dev <pod-name>

# Check if ACR authentication is configured
az aks update -n $AKS_CLUSTER_NAME -g $RESOURCE_GROUP --attach-acr $ACR_NAME

# For ImagePullBackOff, verify image exists
az acr repository show-tags --name $ACR_NAME --repository fabric-rti-mcp
```

#### 2. Authentication Failures

**Symptom:** Logs show "Failed to acquire token" or "Authorization header required"

**Solutions:**

```bash
# Verify workload identity is configured
kubectl describe serviceaccount fabric-rti-mcp -n fabric-rti-mcp-dev

# Check federated credential
az identity federated-credential list \
  --identity-name fabric-rti-mcp-identity \
  --resource-group $RESOURCE_GROUP

# Verify pod has the workload identity label
kubectl get pod -n fabric-rti-mcp-dev <pod-name> -o yaml | grep workload

# Check if managed identity has proper permissions
az role assignment list --assignee $MANAGED_IDENTITY_CLIENT_ID
```

#### 3. Connection Timeouts

**Symptom:** Queries timeout or fail to connect to Kusto/Fabric

**Solutions:**

```bash
# Check network policies
kubectl get networkpolicies -n fabric-rti-mcp-dev

# Verify egress connectivity
kubectl run -it --rm debug -n fabric-rti-mcp-dev --image=nicolaka/netshoot --restart=Never -- \
  curl -v https://api.fabric.microsoft.com

# Check firewall rules on Kusto cluster
# (Azure Portal > Kusto Cluster > Networking)
```

#### 4. High Memory Usage

**Symptom:** Pods being OOMKilled or restarted

**Solutions:**

```bash
# Check resource usage
kubectl top pods -n fabric-rti-mcp-dev

# Increase memory limits
# Edit deployment/kubernetes/overlays/dev/kustomization.yaml
# Increase memory limits in patches section

# Apply changes
kubectl apply -k deployment/kubernetes/overlays/dev
```

### Debugging

Execute commands inside a pod:

```bash
# Get a shell in the pod
kubectl exec -it -n fabric-rti-mcp-dev <pod-name> -- /bin/bash

# Check Python version
kubectl exec -it -n fabric-rti-mcp-dev <pod-name> -- python --version

# Test Azure authentication
kubectl exec -it -n fabric-rti-mcp-dev <pod-name> -- \
  python -c "from azure.identity import DefaultAzureCredential; print(DefaultAzureCredential().get_token('https://management.azure.com/.default'))"
```

## Security Best Practices

### 1. Use Workload Identity

Always prefer Workload Identity over service principals for production:
- No credentials in Kubernetes secrets
- Automatic token rotation
- Fine-grained RBAC

### 2. Network Policies

Implement network policies to restrict pod-to-pod communication:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: fabric-rti-mcp-netpol
  namespace: fabric-rti-mcp
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: fabric-rti-mcp
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: ingress-nginx
    ports:
    - protocol: TCP
      port: 3000
  egress:
  - to:
    - namespaceSelector: {}
    ports:
    - protocol: TCP
      port: 53  # DNS
  - to:
    - podSelector: {}
    ports:
    - protocol: TCP
      port: 443  # HTTPS
```

### 3. Resource Limits

Always set resource limits to prevent resource exhaustion:

```yaml
resources:
  requests:
    memory: "256Mi"
    cpu: "250m"
  limits:
    memory: "1Gi"
    cpu: "1000m"
```

### 4. Pod Security Standards

Enable Pod Security Standards on the namespace:

```bash
kubectl label namespace fabric-rti-mcp-dev \
  pod-security.kubernetes.io/enforce=restricted \
  pod-security.kubernetes.io/audit=restricted \
  pod-security.kubernetes.io/warn=restricted
```

### 5. Secret Management

Use Azure Key Vault for sensitive configuration:

```bash
# Install CSI Secret Store driver
helm repo add csi-secrets-store-provider-azure https://azure.github.io/secrets-store-csi-driver-provider-azure/charts
helm install csi-secrets-store-provider-azure/csi-secrets-store-provider-azure

# Create SecretProviderClass
kubectl apply -f - <<EOF
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: fabric-rti-mcp-secrets
  namespace: fabric-rti-mcp
spec:
  provider: azure
  parameters:
    usePodIdentity: "false"
    useVMManagedIdentity: "true"
    userAssignedIdentityID: "$MANAGED_IDENTITY_CLIENT_ID"
    keyvaultName: "your-keyvault"
    objects: |
      array:
        - |
          objectName: fabric-api-key
          objectType: secret
    tenantId: "your-tenant-id"
EOF
```

### 6. Image Security

Scan images for vulnerabilities:

```bash
# Using Azure Defender for Containers
az security assessment list --query "[?displayName=='Vulnerabilities in container images']"

# Using Trivy
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy image your-acr.azurecr.io/fabric-rti-mcp:latest
```

### 7. Least Privilege RBAC

Grant minimal permissions to the managed identity:

```bash
# Instead of Contributor, use specific roles
az role assignment create \
  --assignee "$MANAGED_IDENTITY_PRINCIPAL_ID" \
  --role "Azure Data Explorer Cluster User" \
  --scope "$KUSTO_CLUSTER_ID"

# Create custom role for Fabric access
az role definition create --role-definition '{
  "Name": "Fabric RTI MCP Reader",
  "Description": "Read-only access to Fabric RTI resources",
  "Actions": [
    "Microsoft.Fabric/workspaces/read",
    "Microsoft.Fabric/workspaces/eventstreams/read"
  ],
  "AssignableScopes": ["/subscriptions/'$SUBSCRIPTION_ID'"]
}'
```

## Production Checklist

Before deploying to production:

- [ ] Workload identity configured and tested
- [ ] Managed identity has minimal required permissions
- [ ] Resource limits and requests properly sized
- [ ] HPA configured with appropriate metrics
- [ ] PodDisruptionBudget ensures high availability
- [ ] Ingress configured with TLS certificates
- [ ] Network policies restrict traffic
- [ ] Monitoring and alerting configured
- [ ] Backup and disaster recovery plan in place
- [ ] Secrets rotated and stored in Azure Key Vault
- [ ] Image vulnerabilities scanned and addressed
- [ ] Pod security standards enforced
- [ ] Logs exported to centralized logging system
- [ ] Runbook created for common operations

## Additional Resources

- [Azure Workload Identity Documentation](https://learn.microsoft.com/en-us/azure/aks/workload-identity-overview)
- [AKS Best Practices](https://learn.microsoft.com/en-us/azure/aks/best-practices)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Fabric RTI Documentation](https://aka.ms/fabricrti)
- [MCP Specification](https://modelcontextprotocol.io/)

## Support

For issues or questions:
- GitHub Issues: https://github.com/microsoft/fabric-rti-mcp/issues
- Documentation: https://github.com/microsoft/fabric-rti-mcp#readme
