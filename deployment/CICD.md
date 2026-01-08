# GitHub Actions CI/CD Configuration

This document explains the GitHub Actions workflows for building and deploying the Fabric RTI MCP Server to AKS.

## Workflow: Build and Deploy to AKS

**File:** `.github/workflows/aks-deploy.yml`

### Triggers

- **Push to `main`**: Deploys to staging
- **Push to `develop`**: Deploys to development
- **Tags `v*`**: Deploys to production
- **Pull requests**: Builds and optionally deploys to dev

### Required Secrets

Configure these in your GitHub repository settings (Settings > Secrets and variables > Actions):

#### Azure Authentication
- `AZURE_CLIENT_ID` - Service principal client ID (for OIDC)
- `AZURE_TENANT_ID` - Azure tenant ID
- `AZURE_SUBSCRIPTION_ID` - Azure subscription ID

#### Azure Resources
- `ACR_NAME` - Azure Container Registry name (without .azurecr.io)
- `RESOURCE_GROUP` - Resource group containing AKS cluster
- `AKS_CLUSTER_NAME` - AKS cluster name

### Setup GitHub OIDC with Azure

1. **Create Azure AD Application:**
   ```bash
   az ad app create --display-name "fabric-rti-mcp-github-actions"
   ```

2. **Create Service Principal:**
   ```bash
   APP_ID=$(az ad app list --display-name "fabric-rti-mcp-github-actions" --query "[0].appId" -o tsv)
   az ad sp create --id $APP_ID
   ```

3. **Configure Federated Credentials:**
   ```bash
   SP_OBJECT_ID=$(az ad sp list --display-name "fabric-rti-mcp-github-actions" --query "[0].id" -o tsv)

   # For main branch
   az ad app federated-credential create \
     --id $APP_ID \
     --parameters '{
       "name": "github-main",
       "issuer": "https://token.actions.githubusercontent.com",
       "subject": "repo:YOUR_ORG/fabric-rti-mcp:ref:refs/heads/main",
       "audiences": ["api://AzureADTokenExchange"]
     }'

   # For develop branch
   az ad app federated-credential create \
     --id $APP_ID \
     --parameters '{
       "name": "github-develop",
       "issuer": "https://token.actions.githubusercontent.com",
       "subject": "repo:YOUR_ORG/fabric-rti-mcp:ref:refs/heads/develop",
       "audiences": ["api://AzureADTokenExchange"]
     }'

   # For pull requests
   az ad app federated-credential create \
     --id $APP_ID \
     --parameters '{
       "name": "github-pr",
       "issuer": "https://token.actions.githubusercontent.com",
       "subject": "repo:YOUR_ORG/fabric-rti-mcp:pull_request",
       "audiences": ["api://AzureADTokenExchange"]
     }'
   ```

4. **Grant Permissions:**
   ```bash
   SP_PRINCIPAL_ID=$(az ad sp list --display-name "fabric-rti-mcp-github-actions" --query "[0].id" -o tsv)

   # AKS permissions
   az role assignment create \
     --assignee $SP_PRINCIPAL_ID \
     --role "Azure Kubernetes Service Cluster User Role" \
     --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.ContainerService/managedClusters/$AKS_CLUSTER_NAME"

   # ACR permissions
   az role assignment create \
     --assignee $SP_PRINCIPAL_ID \
     --role "AcrPush" \
     --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.ContainerRegistry/registries/$ACR_NAME"
   ```

### Environments

Configure GitHub environments for deployment approvals:

1. **Navigate to:** Settings > Environments
2. **Create environments:**
   - `development` (no approvals needed)
   - `staging` (optional: require 1 reviewer)
   - `production` (recommended: require 2 reviewers)

### Jobs

#### 1. Build
- Builds Docker image
- Pushes to ACR
- Scans for vulnerabilities using Trivy
- Tags based on branch/tag

#### 2. Deploy to Dev
- Triggers on: develop branch or PRs
- Environment: development
- Deploys to dev namespace

#### 3. Deploy to Staging
- Triggers on: main branch
- Environment: staging
- Deploys to staging namespace
- Runs smoke tests

#### 4. Deploy to Prod
- Triggers on: version tags (v*)
- Environment: production
- Requires staging deployment success
- Deploys to prod namespace
- Adds deployment annotations

### Image Tags

| Trigger | Image Tag |
|---------|-----------|
| `develop` branch | `dev-latest` |
| `main` branch | `latest` |
| Tag `v1.2.3` | `v1.2.3` |
| PR #123 | `pr-123` |
| Any commit | `<git-sha>` |

### Manual Deployment

To manually trigger a deployment:

1. Go to Actions tab in GitHub
2. Select "Build and Deploy to AKS" workflow
3. Click "Run workflow"
4. Select branch/tag
5. Click "Run workflow"

### Rollback

To rollback to a previous version:

```bash
# Get deployment history
kubectl rollout history deployment/fabric-rti-mcp-prod -n fabric-rti-mcp-prod

# Rollback to previous version
kubectl rollout undo deployment/fabric-rti-mcp-prod -n fabric-rti-mcp-prod

# Rollback to specific revision
kubectl rollout undo deployment/fabric-rti-mcp-prod -n fabric-rti-mcp-prod --to-revision=3
```

### Monitoring Deployments

View deployment status:

```bash
# Watch deployment progress
kubectl get pods -n fabric-rti-mcp-prod -w

# View rollout status
kubectl rollout status deployment/fabric-rti-mcp-prod -n fabric-rti-mcp-prod

# View recent events
kubectl get events -n fabric-rti-mcp-prod --sort-by='.lastTimestamp'
```

## Alternative: Azure Pipelines

If you prefer Azure Pipelines, see `azure-pipelines.yml` (create separately).

## Security Notes

- Never commit secrets to the repository
- Use GitHub's encrypted secrets for sensitive data
- Rotate service principal credentials regularly
- Limit service principal permissions to minimum required
- Enable branch protection rules on `main` and `develop`
- Require pull request reviews before merging

## Troubleshooting

### Authentication Failures

If you see "Azure login failed":
1. Verify federated credentials are configured correctly
2. Check that the subject pattern matches your repo
3. Ensure service principal has required permissions

### Deployment Failures

If deployment fails:
1. Check the workflow logs in GitHub Actions
2. Verify AKS cluster is accessible
3. Check kubectl context and permissions
4. Review pod logs: `kubectl logs -n <namespace> <pod-name>`

### Image Pull Failures

If pods can't pull the image:
1. Verify ACR is attached to AKS
2. Check image exists: `az acr repository show-tags --name $ACR_NAME --repository fabric-rti-mcp`
3. Verify service principal has AcrPull role

## Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Azure Login Action](https://github.com/Azure/login)
- [Azure Kubernetes Service](https://docs.microsoft.com/en-us/azure/aks/)
