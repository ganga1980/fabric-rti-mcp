# Fabric RTI MCP Helm Chart

This Helm chart deploys the Fabric RTI MCP Server on Kubernetes with support for multiple environments and authentication methods.

## Prerequisites

- Kubernetes 1.19+
- Helm 3.2.0+
- PV provisioner support in the underlying infrastructure (optional)

## Installing the Chart

### Install with default values (production configuration)

```bash
helm install fabric-rti-mcp ./deployment/helm/fabric-rti-mcp \
  --namespace fabric-rti-mcp \
  --create-namespace
```

### Install for specific environment

**Development:**
```bash
helm install fabric-rti-mcp ./deployment/helm/fabric-rti-mcp \
  --namespace fabric-rti-mcp-dev \
  --create-namespace \
  --values ./deployment/helm/fabric-rti-mcp/values-dev.yaml
```

**Staging:**
```bash
helm install fabric-rti-mcp ./deployment/helm/fabric-rti-mcp \
  --namespace fabric-rti-mcp-staging \
  --create-namespace \
  --values ./deployment/helm/fabric-rti-mcp/values-staging.yaml
```

**Production:**
```bash
helm install fabric-rti-mcp ./deployment/helm/fabric-rti-mcp \
  --namespace fabric-rti-mcp-prod \
  --create-namespace \
  --values ./deployment/helm/fabric-rti-mcp/values-prod.yaml
```

### Install with custom values

```bash
helm install fabric-rti-mcp ./deployment/helm/fabric-rti-mcp \
  --namespace fabric-rti-mcp \
  --create-namespace \
  --set image.repository=your-acr.azurecr.io/fabric-rti-mcp \
  --set image.tag=v0.2.0 \
  --set ingress.hosts[0].host=your-domain.com
```

## Upgrading the Chart

```bash
helm upgrade fabric-rti-mcp ./deployment/helm/fabric-rti-mcp \
  --namespace fabric-rti-mcp \
  --values ./deployment/helm/fabric-rti-mcp/values-prod.yaml
```

## Uninstalling the Chart

```bash
helm uninstall fabric-rti-mcp --namespace fabric-rti-mcp
```

## Configuration

### Authentication Methods

The chart supports three authentication methods:

#### 1. Workload Identity (Recommended for Azure AKS)

```yaml
config:
  auth:
    method: "workloadIdentity"
    useOboFlow: true

workloadIdentity:
  enabled: true
  labelPods: true
  clientId: "your-umi-client-id"

serviceAccount:
  create: true
  annotations:
    azure.workload.identity/client-id: "your-umi-client-id"

secrets:
  create: true
  obo:
    tenantId: "your-tenant-id"
    entraAppClientId: "your-entra-app-client-id"
    userManagedIdentityClientId: "your-umi-client-id"
    kustoAudience: "https://kusto.kusto.windows.net"
```

#### 2. Service Principal

```yaml
config:
  auth:
    method: "servicePrincipal"
    useOboFlow: false

secrets:
  create: true
  servicePrincipal:
    clientId: "your-sp-client-id"
    clientSecret: "your-sp-client-secret"
    tenantId: "your-tenant-id"
```

#### 3. OBO Flow

```yaml
config:
  auth:
    method: "obo"
    useOboFlow: true

secrets:
  create: true
  obo:
    tenantId: "your-tenant-id"
    entraAppClientId: "your-entra-app-client-id"
    userManagedIdentityClientId: "your-umi-client-id"
    kustoAudience: "https://kusto.kusto.windows.net"
```

### Common Configuration Options

| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicaCount` | Number of replicas | `2` |
| `image.repository` | Image repository | `fabric-rti-mcp` |
| `image.tag` | Image tag | `""` (uses appVersion) |
| `image.pullPolicy` | Image pull policy | `Always` |
| `service.type` | Service type | `ClusterIP` |
| `service.port` | Service port | `80` |
| `ingress.enabled` | Enable ingress | `true` |
| `ingress.className` | Ingress class name | `nginx` |
| `resources.requests.memory` | Memory request | `256Mi` |
| `resources.requests.cpu` | CPU request | `250m` |
| `resources.limits.memory` | Memory limit | `1Gi` |
| `resources.limits.cpu` | CPU limit | `1000m` |
| `autoscaling.enabled` | Enable HPA | `true` |
| `autoscaling.minReplicas` | Minimum replicas | `2` |
| `autoscaling.maxReplicas` | Maximum replicas | `10` |
| `podDisruptionBudget.enabled` | Enable PDB | `true` |
| `podDisruptionBudget.minAvailable` | Min available pods | `1` |

### Environment-Specific Configurations

The chart includes pre-configured values files for different environments:

- **values-dev.yaml**: Development environment with minimal resources
- **values-staging.yaml**: Staging environment with moderate resources
- **values-prod.yaml**: Production environment with full resources and high availability

## Examples

### Example 1: Development with Service Principal

```bash
helm install fabric-rti-mcp ./deployment/helm/fabric-rti-mcp \
  --namespace fabric-rti-mcp-dev \
  --create-namespace \
  --values ./deployment/helm/fabric-rti-mcp/values-dev.yaml \
  --set secrets.servicePrincipal.clientId="dev-client-id" \
  --set secrets.servicePrincipal.clientSecret="dev-client-secret" \
  --set secrets.servicePrincipal.tenantId="dev-tenant-id"
```

### Example 2: Production with Workload Identity

```bash
helm install fabric-rti-mcp ./deployment/helm/fabric-rti-mcp \
  --namespace fabric-rti-mcp-prod \
  --create-namespace \
  --values ./deployment/helm/fabric-rti-mcp/values-prod.yaml \
  --set workloadIdentity.clientId="prod-umi-client-id" \
  --set serviceAccount.annotations."azure\.workload\.identity/client-id"="prod-umi-client-id" \
  --set secrets.obo.tenantId="prod-tenant-id" \
  --set secrets.obo.entraAppClientId="prod-entra-app-client-id" \
  --set secrets.obo.userManagedIdentityClientId="prod-umi-client-id"
```

### Example 3: Custom Domain and TLS

```bash
helm install fabric-rti-mcp ./deployment/helm/fabric-rti-mcp \
  --namespace fabric-rti-mcp \
  --create-namespace \
  --set ingress.hosts[0].host=mcp.yourdomain.com \
  --set ingress.tls[0].hosts[0]=mcp.yourdomain.com \
  --set ingress.tls[0].secretName=mcp-tls-secret \
  --set ingress.annotations."cert-manager\.io/cluster-issuer"=letsencrypt-prod
```

## Advanced Configuration

### Custom Environment Variables

Add custom environment variables to the ConfigMap:

```yaml
config:
  extraEnv:
    CUSTOM_VAR: "custom-value"
    ANOTHER_VAR: "another-value"
```

### Custom Secrets

Add custom secrets:

```yaml
secrets:
  extraSecrets:
    CUSTOM_SECRET: "secret-value"
    ANOTHER_SECRET: "another-secret"
```

### Node Affinity

```yaml
affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
      - matchExpressions:
        - key: workload
          operator: In
          values:
          - production
```

### Pod Anti-Affinity

```yaml
affinity:
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
    - weight: 100
      podAffinityTerm:
        labelSelector:
          matchExpressions:
          - key: app.kubernetes.io/name
            operator: In
            values:
            - fabric-rti-mcp
        topologyKey: kubernetes.io/hostname
```

## Troubleshooting

### Check pod status

```bash
kubectl get pods -n fabric-rti-mcp
```

### View pod logs

```bash
kubectl logs -f -n fabric-rti-mcp -l app.kubernetes.io/name=fabric-rti-mcp
```

### Debug authentication issues

```bash
# For workload identity
kubectl describe pod -n fabric-rti-mcp <pod-name> | grep azure.workload.identity

# For service principal
kubectl get secret -n fabric-rti-mcp fabric-rti-mcp-secrets -o yaml
```

### Test connectivity

```bash
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- \
  curl http://fabric-rti-mcp.fabric-rti-mcp.svc.cluster.local/health
```

## Migration from Kustomize

If you're migrating from the existing Kustomize setup:

1. Review your current kustomization.yaml overlays
2. Map the configurations to the appropriate values file (dev/staging/prod)
3. Update image registry and tags
4. Configure authentication method based on your overlay
5. Install the Helm chart with the corresponding values file

Example migration command:

```bash
# Replace Kustomize overlay with Helm
kubectl delete -k deployment/kubernetes/overlays/prod
helm install fabric-rti-mcp ./deployment/helm/fabric-rti-mcp \
  --namespace fabric-rti-mcp-prod \
  --create-namespace \
  --values ./deployment/helm/fabric-rti-mcp/values-prod.yaml
```

## Support

For issues and questions, please refer to the main repository documentation.
