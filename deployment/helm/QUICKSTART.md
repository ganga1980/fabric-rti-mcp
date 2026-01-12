# Helm Chart Quick Start Guide

This guide will help you quickly deploy Fabric RTI MCP using Helm charts.

## Quick Install

### 1. Development Environment

```bash
# Install with dev configuration
helm install fabric-rti-mcp ./deployment/helm/fabric-rti-mcp \
  --namespace fabric-rti-mcp-dev \
  --create-namespace \
  --values ./deployment/helm/fabric-rti-mcp/values-dev.yaml \
  --set image.repository=your-acr.azurecr.io/fabric-rti-mcp \
  --set image.tag=dev-latest
```

### 2. Staging Environment

```bash
# Install with staging configuration
helm install fabric-rti-mcp ./deployment/helm/fabric-rti-mcp \
  --namespace fabric-rti-mcp-staging \
  --create-namespace \
  --values ./deployment/helm/fabric-rti-mcp/values-staging.yaml \
  --set image.repository=your-acr.azurecr.io/fabric-rti-mcp \
  --set image.tag=staging-latest \
  --set workloadIdentity.clientId=YOUR_STAGING_UMI_CLIENT_ID \
  --set serviceAccount.annotations."azure\.workload\.identity/client-id"=YOUR_STAGING_UMI_CLIENT_ID
```

### 3. Production Environment

```bash
# Install with production configuration
helm install fabric-rti-mcp ./deployment/helm/fabric-rti-mcp \
  --namespace fabric-rti-mcp-prod \
  --create-namespace \
  --values ./deployment/helm/fabric-rti-mcp/values-prod.yaml \
  --set image.repository=your-acr.azurecr.io/fabric-rti-mcp \
  --set image.tag=v0.2.0 \
  --set workloadIdentity.clientId=YOUR_PROD_UMI_CLIENT_ID \
  --set serviceAccount.annotations."azure\.workload\.identity/client-id"=YOUR_PROD_UMI_CLIENT_ID \
  --set ingress.hosts[0].host=mcp.yourdomain.com
```

## Verify Installation

```bash
# Check the release status
helm status fabric-rti-mcp -n fabric-rti-mcp-prod

# Check pods
kubectl get pods -n fabric-rti-mcp-prod

# Check service
kubectl get svc -n fabric-rti-mcp-prod

# View logs
kubectl logs -f -n fabric-rti-mcp-prod -l app.kubernetes.io/name=fabric-rti-mcp
```

## Update Configuration

### Update image tag

```bash
helm upgrade fabric-rti-mcp ./deployment/helm/fabric-rti-mcp \
  --namespace fabric-rti-mcp-prod \
  --reuse-values \
  --set image.tag=v0.2.1
```

### Update specific values

```bash
helm upgrade fabric-rti-mcp ./deployment/helm/fabric-rti-mcp \
  --namespace fabric-rti-mcp-prod \
  --values ./deployment/helm/fabric-rti-mcp/values-prod.yaml \
  --set replicaCount=5
```

## Uninstall

```bash
helm uninstall fabric-rti-mcp -n fabric-rti-mcp-prod
```

## Common Configurations

### Configure Authentication

**Service Principal (Dev):**
```bash
helm install fabric-rti-mcp ./deployment/helm/fabric-rti-mcp \
  --values ./deployment/helm/fabric-rti-mcp/values-dev.yaml \
  --set secrets.servicePrincipal.clientId=YOUR_CLIENT_ID \
  --set secrets.servicePrincipal.clientSecret=YOUR_CLIENT_SECRET \
  --set secrets.servicePrincipal.tenantId=YOUR_TENANT_ID
```

**Workload Identity (Prod):**
```bash
helm install fabric-rti-mcp ./deployment/helm/fabric-rti-mcp \
  --values ./deployment/helm/fabric-rti-mcp/values-prod.yaml \
  --set workloadIdentity.enabled=true \
  --set workloadIdentity.clientId=YOUR_UMI_CLIENT_ID \
  --set serviceAccount.annotations."azure\.workload\.identity/client-id"=YOUR_UMI_CLIENT_ID
```

### Configure Ingress

```bash
helm install fabric-rti-mcp ./deployment/helm/fabric-rti-mcp \
  --set ingress.enabled=true \
  --set ingress.className=nginx \
  --set ingress.hosts[0].host=mcp.example.com \
  --set ingress.tls[0].secretName=mcp-tls \
  --set ingress.tls[0].hosts[0]=mcp.example.com
```

### Configure Resources

```bash
helm install fabric-rti-mcp ./deployment/helm/fabric-rti-mcp \
  --set resources.requests.memory=512Mi \
  --set resources.requests.cpu=500m \
  --set resources.limits.memory=2Gi \
  --set resources.limits.cpu=2000m
```

### Configure Autoscaling

```bash
helm install fabric-rti-mcp ./deployment/helm/fabric-rti-mcp \
  --set autoscaling.enabled=true \
  --set autoscaling.minReplicas=3 \
  --set autoscaling.maxReplicas=20 \
  --set autoscaling.targetCPUUtilizationPercentage=70
```

## CI/CD Integration

### Using Helm in CI/CD Pipeline

```bash
# Dry run to validate
helm install fabric-rti-mcp ./deployment/helm/fabric-rti-mcp \
  --namespace fabric-rti-mcp-prod \
  --values ./deployment/helm/fabric-rti-mcp/values-prod.yaml \
  --dry-run --debug

# Install/Upgrade with wait
helm upgrade --install fabric-rti-mcp ./deployment/helm/fabric-rti-mcp \
  --namespace fabric-rti-mcp-prod \
  --create-namespace \
  --values ./deployment/helm/fabric-rti-mcp/values-prod.yaml \
  --set image.tag=${CI_COMMIT_TAG} \
  --wait --timeout 5m
```

## Next Steps

- Review the full [README](./README.md) for detailed configuration options
- Configure authentication based on your environment
- Set up ingress with your domain and TLS certificates
- Configure monitoring and logging
- Set up CI/CD pipelines for automated deployments
