#!/bin/bash

set -euo pipefail

# Installs the operators the bundled datastores depend on:
#   - CloudNativePG (Postgres)          https://cloudnative-pg.io
#   - RabbitMQ Cluster Operator         https://www.rabbitmq.com/kubernetes/operator/operator-overview
#
# These are cluster-scoped prerequisites (CRDs + a controller Deployment) and only
# need to be installed once per cluster. The hatchet-stack / hatchet-ha charts render
# the Cluster / RabbitmqCluster custom resources these operators reconcile.
#
# Override versions via env if needed.

CNPG_VERSION="${CNPG_VERSION:-1.30.0}"
# Pinned to the latest RabbitMQ Cluster Operator release whose manifest is
# self-contained. From v2.22.0 the bundled manifest requires cert-manager for its
# webhook certificates; 2.21.0 self-signs, so it installs with no extra prerequisite.
RABBITMQ_OPERATOR_VERSION="${RABBITMQ_OPERATOR_VERSION:-2.21.0}"

cnpg_minor="release-$(echo "$CNPG_VERSION" | cut -d. -f1-2)"
CNPG_MANIFEST="https://raw.githubusercontent.com/cloudnative-pg/cloudnative-pg/${cnpg_minor}/releases/cnpg-${CNPG_VERSION}.yaml"
RABBITMQ_MANIFEST="https://github.com/rabbitmq/cluster-operator/releases/download/v${RABBITMQ_OPERATOR_VERSION}/cluster-operator.yml"

echo "Installing CloudNativePG ${CNPG_VERSION}..."
kubectl apply --server-side -f "$CNPG_MANIFEST"

echo "Installing RabbitMQ Cluster Operator ${RABBITMQ_OPERATOR_VERSION}..."
kubectl apply -f "$RABBITMQ_MANIFEST"

echo "Waiting for CloudNativePG controller to be ready..."
kubectl rollout status deployment/cnpg-controller-manager \
    -n cnpg-system --timeout=300s

echo "Waiting for RabbitMQ Cluster Operator to be ready..."
kubectl rollout status deployment/rabbitmq-cluster-operator \
    -n rabbitmq-system --timeout=300s

echo "Operators installed and ready."
