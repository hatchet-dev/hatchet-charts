#!/bin/bash

set -euo pipefail

# Function to clean up
cleanup() {
    kubectl delete namespace loadtest || echo "Failed to delete loadtest namespace"
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

helm dependency build charts/hatchet-ha

helm install hatchet-ha-test charts/hatchet-ha \
    --create-namespace \
    --namespace loadtest \
    --set sharedConfig.grpcBroadcastAddress="hatchet-grpc:7070" \
    --set postgres.primary.resources.limits.memory=1Gi \
    --set postgres.primary.resources.limits.cpu=500m

# Wait for engine deployment
kubectl rollout status deployment/hatchet-grpc -n loadtest --timeout=300s
kubectl wait --for=condition=available deployment/hatchet-grpc -n loadtest --timeout=300s

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
      imagePullPolicy: Always
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
        - --rlKeys
        - "10"
        - --rlLimit
        - "10"
        - --rlDurationUnit
        - "second"
      env:
        - name: HATCHET_CLIENT_TOKEN
          value: $(kubectl get secret hatchet-client-config -n loadtest -o jsonpath='{.data.HATCHET_CLIENT_TOKEN}' | base64 -d)
        - name: HATCHET_CLIENT_NAMESPACE
          value: ${RANDOM_ID}
        - name: HATCHET_CLIENT_TLS_STRATEGY
          value: "none"
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

# Clean up pod
kubectl delete pod ${RANDOM_ID} -n loadtest || echo "Failed to delete pod"

if [[ $LOAD_TEST_EXIT_CODE -ne 0 ]]; then
    echo "Load test failed! Exiting with non-zero code."
    exit 1
fi

echo "Load test completed successfully!"
