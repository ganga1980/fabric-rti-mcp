# Deployment Structure

This directory contains all the necessary files for deploying Fabric RTI MCP Server to Azure Kubernetes Service (AKS).

## Directory Structure

```
deployment/
├── README.md                       # Comprehensive deployment guide
├── QUICKSTART.md                   # 5-minute quick start guide
├── kubernetes/                     # Kubernetes manifests
│   ├── base/                       # Base manifests (common across environments)
│   │   ├── configmap.yaml         # Environment variables configuration
│   │   ├── deployment.yaml        # Main deployment with health checks, resources
│   │   ├── hpa.yaml               # Horizontal Pod Autoscaler
│   │   ├── ingress.yaml           # Ingress configuration for external access
│   │   ├── kustomization.yaml     # Kustomize base configuration
│   │   ├── namespace.yaml         # Namespace definition
│   │   ├── pdb.yaml               # Pod Disruption Budget
│   │   ├── secret.yaml            # Secrets template (OBO, SP credentials)
│   │   ├── service.yaml           # Kubernetes service
│   │   └── serviceaccount.yaml    # Service account for workload identity
│   └── overlays/                  # Environment-specific configurations
│       ├── dev/                   # Development environment
│       │   └── kustomization.yaml # 1 replica, lower resources
│       ├── staging/               # Staging environment
│       │   └── kustomization.yaml # 2 replicas, workload identity enabled
│       └── prod/                  # Production environment
│           └── kustomization.yaml # 3+ replicas, high availability
└── scripts/                       # Deployment automation scripts
    ├── build-and-push.sh          # Build Docker image and push to ACR
    ├── setup-workload-identity.sh # Setup AKS workload identity (recommended)
    └── setup-service-principal.sh # Setup service principal auth (alternative)
```

## Authentication Methods Supported

1. **Workload Identity** (Recommended) - OIDC-based authentication, no secrets
2. **Service Principal** - Client ID/Secret authentication

## Quick Links

- **[Full Deployment Guide](README.md)** - Comprehensive documentation
- **[Quick Start](QUICKSTART.md)** - Get started in 5 minutes
- **Dockerfile** - Located at repository root: `../Dockerfile`
- **.dockerignore** - Located at repository root: `../.dockerignore`

## Deployment Commands

### Development
```bash
kubectl apply -k kubernetes/overlays/dev
```

### Staging
```bash
kubectl apply -k kubernetes/overlays/staging
```

### Production
```bash
kubectl apply -k kubernetes/overlays/prod
```

## Key Features

- ✅ Production-ready Docker image with security best practices
- ✅ Multi-stage Dockerfile with minimal attack surface
- ✅ Non-root user (UID 1000)
- ✅ Health/readiness/liveness probes
- ✅ Horizontal Pod Autoscaling (HPA)
- ✅ Pod Disruption Budgets (PDB)
- ✅ Resource limits and requests
- ✅ Security contexts and seccomp profiles
- ✅ NGINX Ingress support
- ✅ TLS/SSL with cert-manager integration
- ✅ Workload identity for secure authentication
- ✅ Environment-specific configurations via Kustomize
- ✅ Automated setup scripts

## Support

For issues or questions, see the [main project README](../README.md).
