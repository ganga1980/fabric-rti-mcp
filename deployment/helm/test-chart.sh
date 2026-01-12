#!/bin/bash
set -e

# Helm Chart Test and Validation Script

CHART_DIR="deployment/helm/fabric-rti-mcp"

echo "=========================================="
echo "Fabric RTI MCP Helm Chart Validation"
echo "=========================================="
echo ""

# Check if helm is installed
if ! command -v helm &> /dev/null; then
    echo "❌ ERROR: helm is not installed"
    echo "Please install helm: https://helm.sh/docs/intro/install/"
    exit 1
fi
echo "✅ Helm is installed: $(helm version --short)"
echo ""

# Lint the chart
echo "Step 1: Linting chart..."
if helm lint $CHART_DIR; then
    echo "✅ Chart lint passed"
else
    echo "❌ Chart lint failed"
    exit 1
fi
echo ""

# Lint with dev values
echo "Step 2: Linting with dev values..."
if helm lint $CHART_DIR --values $CHART_DIR/values-dev.yaml; then
    echo "✅ Dev values lint passed"
else
    echo "❌ Dev values lint failed"
    exit 1
fi
echo ""

# Lint with staging values
echo "Step 3: Linting with staging values..."
if helm lint $CHART_DIR --values $CHART_DIR/values-staging.yaml; then
    echo "✅ Staging values lint passed"
else
    echo "❌ Staging values lint failed"
    exit 1
fi
echo ""

# Lint with prod values
echo "Step 4: Linting with prod values..."
if helm lint $CHART_DIR --values $CHART_DIR/values-prod.yaml; then
    echo "✅ Production values lint passed"
else
    echo "❌ Production values lint failed"
    exit 1
fi
echo ""

# Template rendering test
echo "Step 5: Testing template rendering..."
if helm template test $CHART_DIR --values $CHART_DIR/values-dev.yaml > /tmp/helm-test-dev.yaml; then
    echo "✅ Dev template rendering successful"
    echo "   Generated YAML: /tmp/helm-test-dev.yaml"
else
    echo "❌ Dev template rendering failed"
    exit 1
fi

if helm template test $CHART_DIR --values $CHART_DIR/values-prod.yaml > /tmp/helm-test-prod.yaml; then
    echo "✅ Production template rendering successful"
    echo "   Generated YAML: /tmp/helm-test-prod.yaml"
else
    echo "❌ Production template rendering failed"
    exit 1
fi
echo ""

# Dry run test
echo "Step 6: Dry run deployment test..."
if helm install test $CHART_DIR \
    --values $CHART_DIR/values-dev.yaml \
    --set image.repository=test-registry/fabric-rti-mcp \
    --set image.tag=test-tag \
    --dry-run > /dev/null 2>&1; then
    echo "✅ Dry run successful"
else
    echo "❌ Dry run failed"
    exit 1
fi
echo ""

# Count resources
echo "Step 7: Analyzing generated resources..."
DEV_RESOURCES=$(helm template test $CHART_DIR --values $CHART_DIR/values-dev.yaml | grep "^kind:" | wc -l)
PROD_RESOURCES=$(helm template test $CHART_DIR --values $CHART_DIR/values-prod.yaml | grep "^kind:" | wc -l)
echo "✅ Dev environment resources: $DEV_RESOURCES"
echo "✅ Production environment resources: $PROD_RESOURCES"
echo ""

# Check for required resources
echo "Step 8: Verifying required resources..."
REQUIRED_RESOURCES=("Deployment" "Service" "ConfigMap" "Secret" "ServiceAccount" "Ingress" "HorizontalPodAutoscaler" "PodDisruptionBudget")
TEMPLATE_OUTPUT=$(helm template test $CHART_DIR --values $CHART_DIR/values-prod.yaml)

for resource in "${REQUIRED_RESOURCES[@]}"; do
    if echo "$TEMPLATE_OUTPUT" | grep -q "kind: $resource"; then
        echo "✅ $resource found"
    else
        echo "❌ $resource not found"
        exit 1
    fi
done
echo ""

# Package test
echo "Step 9: Testing chart packaging..."
if helm package $CHART_DIR --destination /tmp > /dev/null 2>&1; then
    echo "✅ Chart packaging successful"
    PACKAGE_FILE=$(ls -t /tmp/fabric-rti-mcp-*.tgz 2>/dev/null | head -1)
    if [ -f "$PACKAGE_FILE" ]; then
        echo "   Package created: $PACKAGE_FILE"
        echo "   Size: $(du -h $PACKAGE_FILE | cut -f1)"
    fi
else
    echo "❌ Chart packaging failed"
    exit 1
fi
echo ""

# Validate auth methods
echo "Step 10: Validating authentication configurations..."

# Service Principal
SP_OUTPUT=$(helm template test $CHART_DIR --values $CHART_DIR/values-dev.yaml)
if echo "$SP_OUTPUT" | grep -q "AZURE_CLIENT_ID"; then
    echo "✅ Service Principal auth configuration validated"
else
    echo "⚠️  Service Principal auth configuration not found (may be optional)"
fi

# Workload Identity
WI_OUTPUT=$(helm template test $CHART_DIR --values $CHART_DIR/values-prod.yaml)
if echo "$WI_OUTPUT" | grep -q "azure.workload.identity/use"; then
    echo "✅ Workload Identity configuration validated"
else
    echo "⚠️  Workload Identity configuration not found"
fi
echo ""

echo "=========================================="
echo "✅ All validation checks passed!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Review the generated templates:"
echo "   - Dev: /tmp/helm-test-dev.yaml"
echo "   - Prod: /tmp/helm-test-prod.yaml"
echo ""
echo "2. Install the chart:"
echo "   helm install fabric-rti-mcp $CHART_DIR -f $CHART_DIR/values-dev.yaml"
echo ""
echo "3. Check the documentation:"
echo "   - Quick Start: deployment/helm/QUICKSTART.md"
echo "   - Full Docs: deployment/helm/README.md"
echo ""
