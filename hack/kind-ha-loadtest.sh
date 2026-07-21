#!/bin/bash

set -euo pipefail

# Function to print debugging info for failed deployments
print_deployment_debug() {
    local deployment=$1
    local namespace=$2

    echo "=========================================="
    echo "DEBUGGING DEPLOYMENT FAILURE: $deployment"
    echo "=========================================="

    # Check if namespace exists
    if ! kubectl get namespace "$namespace" &> /dev/null; then
        echo "ERROR: Namespace '$namespace' does not exist!"
        return
    fi

    # Get deployment status
    echo ""
    echo "--- Deployment Status ---"
    kubectl get deployment "$deployment" -n "$namespace" -o wide || echo "Failed to get deployment"

    echo ""
    echo "--- Deployment Description ---"
    kubectl describe deployment "$deployment" -n "$namespace" || echo "Failed to describe deployment"

    # Get pods
    echo ""
    echo "--- Pods ---"
    kubectl get pods -n "$namespace" -l "app.kubernetes.io/instance=hatchet-ha-test" -o wide || echo "Failed to get pods"

    # Describe pods
    echo ""
    echo "--- Pod Details ---"
    for pod in $(kubectl get pods -n "$namespace" -l "app.kubernetes.io/instance=hatchet-ha-test" -o name 2>/dev/null); do
        echo ""
        echo "Describing $pod:"
        kubectl describe "$pod" -n "$namespace"
    done

    # Get pod logs
    echo ""
    echo "--- Pod Logs ---"
    for pod in $(kubectl get pods -n "$namespace" -l "app.kubernetes.io/instance=hatchet-ha-test" -o name 2>/dev/null); do
        echo ""
        echo "Logs for $pod:"
        kubectl logs "$pod" -n "$namespace" --all-containers=true --tail=100 || echo "Failed to get logs for $pod"
    done

    # Get events
    echo ""
    echo "--- Recent Events ---"
    kubectl get events -n "$namespace" --sort-by='.lastTimestamp' || echo "Failed to get events"

    # Check resource availability
    echo ""
    echo "--- Node Resources ---"
    kubectl top nodes || echo "Metrics not available"

    echo ""
    echo "=========================================="
}

# Function to clean up
cleanup() {
    # Check if namespace exists before trying to delete
    if kubectl get namespace loadtest &> /dev/null; then
        echo "Cleaning up loadtest namespace..."
        kubectl delete namespace loadtest || echo "Failed to delete loadtest namespace"
    else
        echo "Namespace loadtest does not exist, skipping cleanup"
    fi
}

# Register the cleanup function to be called on the EXIT signal
trap cleanup EXIT

# Check required environment variables
required_vars=(
    "VERSION"
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

"$(dirname "$0")/install-operators.sh"

helm dependency build charts/hatchet-ha

# Create the namespace up front so the engine has somewhere to land before install.
kubectl create namespace loadtest --dry-run=client -o yaml | kubectl apply -f -

# Engine traces are shipped to ClickStack Cloud via an in-cluster ClickStack OTel
# collector: the engine exports OTLP to svc `otel-collector:4317` (plaintext,
# in-cluster) and the collector forwards spans to ClickHouse Cloud over TLS using the
# credentials below (provided via GitHub secrets in CI). When any credential is unset
# the collector is skipped and the engine's OTLP export is a no-op, so local runs work
# without any secrets.
otel_args=()
if [[ -n "${CLICKHOUSE_ENDPOINT:-}" && -n "${CLICKHOUSE_USER:-}" && -n "${CLICKHOUSE_PASSWORD:-}" ]]; then
    # Wake the ClickHouse Cloud service before the collector starts writing. A
    # scaled-to-zero instance resumes on any HTTP hit; poll /ping until it's back
    # (up to ~60s). Mirrors the wake-clickhouse job in hatchet-cloud's build.yml.
    echo "Waking ClickHouse Cloud (${CLICKHOUSE_ENDPOINT%/}/ping)..."
    curl -sS --retry 30 --retry-delay 2 --retry-all-errors "${CLICKHOUSE_ENDPOINT%/}/ping" \
        || echo "WARNING: ClickHouse wake ping failed; collector writes may lag until it resumes"

    echo "Deploying in-cluster ClickStack OTel collector (ships traces to ClickHouse Cloud)..."
    kubectl create secret generic clickstack-otel -n loadtest \
        --from-literal=CLICKHOUSE_ENDPOINT="${CLICKHOUSE_ENDPOINT}" \
        --from-literal=CLICKHOUSE_USER="${CLICKHOUSE_USER}" \
        --from-literal=CLICKHOUSE_PASSWORD="${CLICKHOUSE_PASSWORD}" \
        --dry-run=client -o yaml | kubectl apply -f -
    kubectl apply -n loadtest -f hack/loadtest-otel.yaml
    kubectl rollout status deployment/otel-collector -n loadtest --timeout=120s || echo "WARNING: collector not ready; engine traces may be unavailable"
    otel_args=(
        --set-string sharedConfig.env.SERVER_OTEL_COLLECTOR_URL=otel-collector:4317
        --set-string sharedConfig.env.SERVER_OTEL_INSECURE=true
        --set-string sharedConfig.env.SERVER_OTEL_SERVICE_NAME=hatchet-loadtest-ha
        --set-string sharedConfig.env.SERVER_OTEL_TRACE_ID_RATIO=0.5
    )
else
    echo "CLICKHOUSE_ENDPOINT / CLICKHOUSE_USER / CLICKHOUSE_PASSWORD not set; engine trace export disabled."
fi

helm install hatchet-ha-test charts/hatchet-ha \
    --create-namespace \
    --namespace loadtest \
    ${otel_args[@]+"${otel_args[@]}"} \
    --set sharedConfig.grpcBroadcastAddress="hatchet-grpc:7070" \
    --set postgres.primary.resources.limits.memory=1Gi \
    --set postgres.primary.resources.limits.cpu=500m \
    --set postgres.primary.extendedConfiguration="timezone='UTC'"

# Wait for engine deployment
echo "Waiting for engine deployment to be ready..."
if ! kubectl rollout status deployment/hatchet-grpc -n loadtest --timeout=300s; then
    echo ""
    echo "ERROR: Engine deployment rollout failed!"
    print_deployment_debug "hatchet-grpc" "loadtest"
    exit 1
fi

if ! kubectl wait --for=condition=available deployment/hatchet-grpc -n loadtest --timeout=300s; then
    echo ""
    echo "ERROR: Engine deployment did not become available!"
    print_deployment_debug "hatchet-grpc" "loadtest"
    exit 1
fi

echo "Engine deployment is ready!"

# Sleep for 30 seconds
echo "Sleeping for 30 seconds to allow services to stabilize..."

# Run load test
echo "Running load test..."

# Generate random identifier for the pod
RANDOM_ID="loadtest-$(date +%s)"
echo "Load test pod name: $RANDOM_ID"

# Create load test pod
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: ${RANDOM_ID}
  namespace: loadtest
spec:
  restartPolicy: Never
  containers:
    - image: ghcr.io/hatchet-dev/hatchet/hatchet-loadtest:${VERSION}
      imagePullPolicy: IfNotPresent
      name: loadtest
      command: ["/hatchet/hatchet-load-test"]
      args:
        - loadtest
        - --duration
        - "60s"
        - --events
        - "5"
        - --level
        - warn
        - --slots
        - "1000"
        - --dagSteps
        - "2"
        - --averageDurationThreshold
        - "10s"
        - --rlKeys
        - "10"
        - --rlLimit
        - "20"
        - --rlDurationUnit
        - "second"
      env:
        - name: HATCHET_CLIENT_TOKEN
          value: $(kubectl get secret hatchet-client-config -n loadtest -o jsonpath='{.data.HATCHET_CLIENT_TOKEN}' | base64 -d)
        - name: HATCHET_CLIENT_NAMESPACE
          value: ${RANDOM_ID}
        - name: HATCHET_CLIENT_TLS_STRATEGY
          value: "none"
        - name: HATCHET_CLIENT_DISABLE_GZIP_COMPRESSION
          value: "true"
      resources:
        limits:
          memory: 512Mi
        requests:
          cpu: 200m
          memory: 256Mi
EOF

# Wait for pod to complete (timeout after 10 minutes)
echo "Waiting for load test pod to complete..."
kubectl wait --for=condition=Ready pod/${RANDOM_ID} -n loadtest --timeout=30s

# Wait for pod to finish (either succeed or fail)
echo "Waiting for load test to finish..."
LOAD_TEST_EXIT_CODE=0
kubectl wait --for=condition=ContainersReady=false pod/${RANDOM_ID} -n loadtest --timeout=240s || {
    echo "Pod did not complete within timeout"
    LOAD_TEST_EXIT_CODE=1
}

# Give the pod a moment to transition to final state
sleep 5

# Get final pod status
POD_STATUS=$(kubectl get pod ${RANDOM_ID} -n loadtest -o jsonpath='{.status.phase}')
echo "Final pod status: $POD_STATUS"

# Capture logs
echo "Capturing load test logs..."
kubectl logs ${RANDOM_ID} -n loadtest > /tmp/loadtest-logs.txt || echo "Failed to capture logs"

# Show logs for debugging
echo "Load test output:"
cat /tmp/loadtest-logs.txt

# Check if the load test actually succeeded by looking at the logs and pod status
if [[ "$POD_STATUS" == "Succeeded" ]]; then
    LOAD_TEST_STATUS="✅ PASSED"
    LOAD_TEST_EMOJI="✅"
    LOAD_TEST_EXIT_CODE=0
elif [[ "$POD_STATUS" == "Failed" ]]; then
    LOAD_TEST_STATUS="❌ FAILED"
    LOAD_TEST_EMOJI="❌"
    LOAD_TEST_EXIT_CODE=1
else
    # Pod is still running or in unknown state - check container exit code
    CONTAINER_EXIT_CODE=$(kubectl get pod ${RANDOM_ID} -n loadtest -o jsonpath='{.status.containerStatuses[0].state.terminated.exitCode}' 2>/dev/null || echo "")
    if [[ "$CONTAINER_EXIT_CODE" == "0" ]]; then
        LOAD_TEST_STATUS="✅ PASSED"
        LOAD_TEST_EMOJI="✅"
        LOAD_TEST_EXIT_CODE=0
    elif [[ -n "$CONTAINER_EXIT_CODE" ]]; then
        LOAD_TEST_STATUS="❌ FAILED (exit code: $CONTAINER_EXIT_CODE)"
        LOAD_TEST_EMOJI="❌"
        LOAD_TEST_EXIT_CODE=1
    else
        # Check logs for success indicator as fallback
        if grep -q "✅ success" /tmp/loadtest-logs.txt; then
            LOAD_TEST_STATUS="✅ PASSED (detected from logs)"
            LOAD_TEST_EMOJI="✅"
            LOAD_TEST_EXIT_CODE=0
        else
            LOAD_TEST_STATUS="❌ FAILED (unknown state: $POD_STATUS)"
            LOAD_TEST_EMOJI="❌"
            LOAD_TEST_EXIT_CODE=1
        fi
    fi
fi

# --- KPI summary as a CI artifact (best-effort) ---
# Engine traces for this run live in ClickStack Cloud (service hatchet-loadtest-ha),
# so there is nothing to export from the cluster before the cleanup trap tears it down.
if [[ -n "${CLICKHOUSE_ENDPOINT:-}" ]]; then
    echo "Engine traces exported to ClickStack Cloud (service: hatchet-loadtest-ha)."
fi

# Parse the loadtest binary's own summary lines into a machine-readable summary.
AVG_DURATION=$(grep -oE 'final average duration per executed event: .*' /tmp/loadtest-logs.txt | tail -1 | sed 's/.*event: //' || echo "")
AVG_SCHEDULING=$(grep -oE 'final average scheduling time per event: .*' /tmp/loadtest-logs.txt | tail -1 | sed 's/.*event: //' || echo "")
COUNTS_LINE=$(grep -oE 'pushed [0-9]+, executed [0-9]+, uniques [0-9]+[^)]*\)' /tmp/loadtest-logs.txt | tail -1 || echo "")
cat > /tmp/loadtest-summary.json <<JSON
{
  "scenario": "ha",
  "version": "${VERSION}",
  "result": "${LOAD_TEST_STATUS}",
  "averageDuration": "${AVG_DURATION}",
  "averageScheduling": "${AVG_SCHEDULING}",
  "counts": "${COUNTS_LINE}"
}
JSON
echo "Wrote /tmp/loadtest-summary.json:"
cat /tmp/loadtest-summary.json

# One-line summary for the GitHub Actions run summary (no-op locally).
if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
    {
        echo "### Loadtest (ha) — ${VERSION}"
        echo ""
        echo "| Result | Avg duration | Avg scheduling | Counts |"
        echo "| --- | --- | --- | --- |"
        echo "| ${LOAD_TEST_STATUS} | ${AVG_DURATION:-n/a} | ${AVG_SCHEDULING:-n/a} | ${COUNTS_LINE:-n/a} |"
    } >> "$GITHUB_STEP_SUMMARY"
fi

# Clean up pod
kubectl delete pod ${RANDOM_ID} -n loadtest || echo "Failed to delete pod"

if [[ $LOAD_TEST_EXIT_CODE -ne 0 ]]; then
    echo "Load test failed! Exiting with non-zero code."
    exit 1
fi

echo "Load test completed successfully!"
