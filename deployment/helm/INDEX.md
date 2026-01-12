# Helm Chart for Fabric RTI MCP - Complete Guide

## 📋 Table of Contents

1. [Quick Start](#quick-start)
2. [What's Included](#whats-included)
3. [Documentation](#documentation)
4. [Installation](#installation)
5. [Validation](#validation)
6. [Support](#support)

## 🚀 Quick Start

### Install Development Environment

```bash
helm install fabric-rti-mcp ./deployment/helm/fabric-rti-mcp \
  --namespace fabric-rti-mcp-dev \
  --create-namespace \
  --values ./deployment/helm/fabric-rti-mcp/values-dev.yaml \
  --set image.repository=your-acr.azurecr.io/fabric-rti-mcp \
  --set image.tag=dev-latest
```

### Install Production Environment

```bash
helm install fabric-rti-mcp ./deployment/helm/fabric-rti-mcp \
  --namespace fabric-rti-mcp-prod \
  --create-namespace \
  --values ./deployment/helm/fabric-rti-mcp/values-prod.yaml \
  --set image.repository=your-acr.azurecr.io/fabric-rti-mcp \
  --set image.tag=v0.2.0 \
  --set workloadIdentity.clientId=YOUR_UMI_CLIENT_ID \
  --set serviceAccount.annotations."azure\.workload\.identity/client-id"=YOUR_UMI_CLIENT_ID
```

📖 **Full Quick Start Guide**: [QUICKSTART.md](./QUICKSTART.md)

## 📦 What's Included

### Helm Chart Structure

```
deployment/helm/fabric-rti-mcp/
├── Chart.yaml                    # Chart metadata
├── values.yaml                   # Default configuration
├── values-dev.yaml               # Dev environment overrides
├── values-staging.yaml           # Staging environment overrides
├── values-prod.yaml              # Production environment overrides
└── templates/
    ├── _helpers.tpl              # Template helpers
    ├── NOTES.txt                 # Post-install notes
    ├── serviceaccount.yaml       # Service account
    ├── configmap.yaml            # Configuration
    ├── secret.yaml               # Secrets
    ├── deployment.yaml           # Application deployment
    ├── service.yaml              # Service
    ├── ingress.yaml              # Ingress (optional)
    ├── hpa.yaml                  # Horizontal Pod Autoscaler
    └── pdb.yaml                  # Pod Disruption Budget
```

### Key Features

✅ **Three Authentication Methods**
- Service Principal
- Workload Identity
- OBO Flow

✅ **Environment-Specific Configurations**
- Development (minimal resources)
- Staging (moderate resources)
- Production (full resources, HA)

✅ **Advanced Features**
- Automatic scaling (HPA)
- High availability (PDB)
- Security hardening
- Health probes
- Rolling updates

✅ **Easy Configuration**
- Single values file per environment
- Runtime value overrides
- Conditional resource creation

## 📚 Documentation

| Document | Description | Link |
|----------|-------------|------|
| **Quick Start** | Get started in 5 minutes | [QUICKSTART.md](./QUICKSTART.md) |
| **Complete Guide** | Full documentation with all options | [README.md](./README.md) |
| **Migration Guide** | Migrate from Kustomize to Helm | [MIGRATION.md](./MIGRATION.md) |
| **Comparison** | Helm vs Kustomize detailed comparison | [COMPARISON.md](./COMPARISON.md) |
| **Summary** | Overview of the conversion | [SUMMARY.md](./SUMMARY.md) |
| **CI/CD Example** | GitHub Actions workflow | [.github-workflow-example.yaml](./.github-workflow-example.yaml) |

## 🛠️ Installation

### Prerequisites

- Kubernetes 1.19+
- Helm 3.2.0+
- kubectl configured

### Installation Commands

**Development:**
```bash
helm install fabric-rti-mcp ./deployment/helm/fabric-rti-mcp \
  -n fabric-rti-mcp-dev --create-namespace \
  -f ./deployment/helm/fabric-rti-mcp/values-dev.yaml
```

**Staging:**
```bash
helm install fabric-rti-mcp ./deployment/helm/fabric-rti-mcp \
  -n fabric-rti-mcp-staging --create-namespace \
  -f ./deployment/helm/fabric-rti-mcp/values-staging.yaml
```

**Production:**
```bash
helm install fabric-rti-mcp ./deployment/helm/fabric-rti-mcp \
  -n fabric-rti-mcp-prod --create-namespace \
  -f ./deployment/helm/fabric-rti-mcp/values-prod.yaml
```

### Automated Deployment

Use the provided deployment script:

```bash
# Set environment variables
export ENVIRONMENT=dev
export IMAGE_REPOSITORY=your-acr.azurecr.io/fabric-rti-mcp
export IMAGE_TAG=dev-latest

# Run deployment script
./deployment/helm/deploy.sh
```

## ✅ Validation

### Validate Chart

```bash
# Run comprehensive validation
./deployment/helm/test-chart.sh
```

### Manual Validation

```bash
# Lint chart
helm lint deployment/helm/fabric-rti-mcp

# Lint with specific values
helm lint deployment/helm/fabric-rti-mcp --values deployment/helm/fabric-rti-mcp/values-prod.yaml

# Test template rendering
helm template test deployment/helm/fabric-rti-mcp \
  --values deployment/helm/fabric-rti-mcp/values-dev.yaml

# Dry run
helm install test deployment/helm/fabric-rti-mcp \
  --values deployment/helm/fabric-rti-mcp/values-dev.yaml \
  --dry-run --debug
```

### Validation Status

✅ All charts pass lint validation
✅ All environment values files validated
✅ Template rendering successful
✅ Dry run deployments pass
✅ Chart packaging successful
✅ Authentication configurations validated

## 🔐 Authentication Configuration

### Service Principal (Development)

```yaml
config:
  auth:
    method: "servicePrincipal"
secrets:
  servicePrincipal:
    clientId: "your-client-id"
    clientSecret: "your-client-secret"
    tenantId: "your-tenant-id"
```

### Workload Identity (Production)

```yaml
config:
  auth:
    method: "workloadIdentity"
    useOboFlow: true
workloadIdentity:
  enabled: true
  clientId: "your-umi-client-id"
serviceAccount:
  annotations:
    azure.workload.identity/client-id: "your-umi-client-id"
```

## 📊 Environment Comparison

| Feature | Dev | Staging | Production |
|---------|-----|---------|------------|
| Replicas | 1 | 2 | 3 |
| Memory Request | 128Mi | 256Mi | 512Mi |
| Memory Limit | 512Mi | 768Mi | 2Gi |
| CPU Request | 100m | 250m | 500m |
| CPU Limit | 500m | 750m | 2000m |
| HPA Min | 1 | 2 | 3 |
| HPA Max | 3 | 6 | 20 |
| PDB Min Available | 1 | 1 | 2 |
| Auth Method | Service Principal | Workload Identity | Workload Identity |
| Ingress | Optional | Enabled | Enabled |

## 🔄 Common Operations

### Upgrade Chart

```bash
helm upgrade fabric-rti-mcp ./deployment/helm/fabric-rti-mcp \
  -n fabric-rti-mcp-prod \
  -f ./deployment/helm/fabric-rti-mcp/values-prod.yaml \
  --set image.tag=v0.2.1
```

### Rollback

```bash
# Rollback to previous version
helm rollback fabric-rti-mcp -n fabric-rti-mcp-prod

# Rollback to specific revision
helm rollback fabric-rti-mcp 3 -n fabric-rti-mcp-prod
```

### Check Status

```bash
# Helm release status
helm status fabric-rti-mcp -n fabric-rti-mcp-prod

# View history
helm history fabric-rti-mcp -n fabric-rti-mcp-prod

# Get current values
helm get values fabric-rti-mcp -n fabric-rti-mcp-prod
```

### Uninstall

```bash
helm uninstall fabric-rti-mcp -n fabric-rti-mcp-prod
```

## 🐛 Troubleshooting

### Check Pods

```bash
kubectl get pods -n fabric-rti-mcp-prod
kubectl logs -f -n fabric-rti-mcp-prod -l app.kubernetes.io/name=fabric-rti-mcp
```

### Debug Template

```bash
helm template debug deployment/helm/fabric-rti-mcp \
  -f deployment/helm/fabric-rti-mcp/values-prod.yaml \
  --debug
```

### Validate Generated YAML

```bash
helm template test deployment/helm/fabric-rti-mcp \
  -f deployment/helm/fabric-rti-mcp/values-prod.yaml | \
  kubectl apply --dry-run=client -f -
```

## 📞 Support

### Resources

- **Complete Documentation**: [README.md](./README.md)
- **Quick Start Guide**: [QUICKSTART.md](./QUICKSTART.md)
- **Migration Guide**: [MIGRATION.md](./MIGRATION.md)
- **Comparison**: [COMPARISON.md](./COMPARISON.md)

### Scripts

- **Deployment Script**: [deploy.sh](./deploy.sh)
- **Validation Script**: [test-chart.sh](./test-chart.sh)
- **CI/CD Example**: [.github-workflow-example.yaml](./.github-workflow-example.yaml)

### Common Issues

**Issue**: Chart lint fails
**Solution**: Run `./deployment/helm/test-chart.sh` to identify the issue

**Issue**: Pod fails to start
**Solution**: Check secrets are properly configured: `kubectl get secret -n <namespace>`

**Issue**: Authentication fails
**Solution**: Verify authentication method in values file matches your Azure setup

**Issue**: Ingress not working
**Solution**: Check ingress controller is installed and className matches your cluster

## 🎯 Next Steps

1. **Review Documentation**: Start with [QUICKSTART.md](./QUICKSTART.md)
2. **Customize Values**: Update image repository and domain names
3. **Configure Authentication**: Set up credentials for your environment
4. **Deploy to Dev**: Test deployment in development environment
5. **Setup CI/CD**: Use provided workflow example
6. **Deploy to Production**: Roll out to production with confidence

---

**Chart Version**: 0.2.0
**App Version**: 0.2.0
**Created**: January 12, 2026
**Status**: ✅ Validated and Ready for Use
