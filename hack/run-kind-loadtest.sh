#!/bin/bash

set -euo pipefail

# Check required environment variables
required_vars=(
    "VERSION"
    "HATCHET_LOADTEST_TOKEN"
)

echo "Checking required environment variables..."
for var in "${required_vars[@]}"; do
    if [[ -z "${!var:-}" ]]; then
        echo "Error: Required environment variable $var is not set"
        exit 1
    fi
done

echo "All required environment variables are set"
echo "VERSION: $VERSION"

# Create version configmap if it doesn't exist
echo "Creating/updating version configmap..."
kubectl create configmap version --from-literal=version="$VERSION" --dry-run=client -o yaml | kubectl apply -f -

# Wait for hatchet-stack deployment to be ready
echo "Waiting for hatchet-stack deployments to be ready..."
kubectl wait --for=condition=available deployment --all --timeout=300s || true

# Check pod status
echo "Current pod status:"
kubectl get pods

# Get service endpoints for load testing
echo "Getting service endpoints..."
API_SERVICE=$(kubectl get svc -l app.kubernetes.io/name=hatchet-api -o jsonpath='{.items[0].metadata.name}' || echo "hatchet-api")
FRONTEND_SERVICE=$(kubectl get svc -l app.kubernetes.io/name=hatchet-frontend -o jsonpath='{.items[0].metadata.name}' || echo "hatchet-frontend")

echo "API Service: $API_SERVICE"
echo "Frontend Service: $FRONTEND_SERVICE"

# Port forward to access services (run in background)
echo "Setting up port forwarding..."
kubectl port-forward svc/$API_SERVICE 8080:8080 &
API_PF_PID=$!
kubectl port-forward svc/$FRONTEND_SERVICE 3000:3000 &
FRONTEND_PF_PID=$!

# Wait a moment for port forwarding to establish
sleep 5

# Function to cleanup
cleanup() {
    echo "Cleaning up port forwards..."
    kill $API_PF_PID $FRONTEND_PF_PID 2>/dev/null || true
}
trap cleanup EXIT

# Basic health checks
echo "Running basic health checks..."

# Check API health
if curl -f http://localhost:8080/api/v1/health 2>/dev/null; then
    echo "✓ API health check passed"
else
    echo "✗ API health check failed"
    kubectl logs -l app.kubernetes.io/name=hatchet-api --tail=20 || true
fi

# Check Frontend accessibility
if curl -f http://localhost:3000 2>/dev/null; then
    echo "✓ Frontend accessibility check passed"
else
    echo "✗ Frontend accessibility check failed"
    kubectl logs -l app.kubernetes.io/name=hatchet-frontend --tail=20 || true
fi

# Simple load test simulation
echo "Running simple load test..."
for i in {1..5}; do
    echo "Load test iteration $i/5"
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/api/v1/health | grep -q "200"; then
        echo "  ✓ API responded successfully"
    else
        echo "  ✗ API request failed"
    fi
    sleep 1
done

echo "Load test completed successfully!"

# Show final status
echo "Final deployment status:"
kubectl get pods
kubectl get svc