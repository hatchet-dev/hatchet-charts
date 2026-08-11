#!/bin/bash

set -euo pipefail

CNPG_VERSION="${CNPG_VERSION:-1.30.0}"
RABBITMQ_OPERATOR_VERSION="${RABBITMQ_OPERATOR_VERSION:-2.21.0}"
FORCE="${FORCE:-}"

CNPG_MANIFEST="https://github.com/cloudnative-pg/cloudnative-pg/releases/download/v${CNPG_VERSION}/cnpg-${CNPG_VERSION}.yaml"
RABBITMQ_MANIFEST="https://github.com/rabbitmq/cluster-operator/releases/download/v${RABBITMQ_OPERATOR_VERSION}/cluster-operator.yml"

install_operator() {
  local label="$1" deploy="$2" namespace="$3" manifest="$4"
  shift 4

  if [[ -z "$FORCE" ]] && kubectl get deployment "$deploy" -n "$namespace" >/dev/null 2>&1; then
    echo "$label already installed in namespace $namespace; skipping (set FORCE=1 to reapply)."
    return
  fi

  echo "Installing $label..."
  kubectl apply "$@" -f "$manifest"
  kubectl rollout status "deployment/$deploy" -n "$namespace" --timeout=300s
}

install_operator "CloudNativePG ${CNPG_VERSION}" \
  cnpg-controller-manager cnpg-system "$CNPG_MANIFEST" --server-side
install_operator "RabbitMQ Cluster Operator ${RABBITMQ_OPERATOR_VERSION}" \
  rabbitmq-cluster-operator rabbitmq-system "$RABBITMQ_MANIFEST"

echo "Operators ready."
