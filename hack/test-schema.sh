#!/usr/bin/env bash
# Verifies that each chart's values.schema.json actually rejects invalid values.
# For every "bad" override we assert `helm template` FAILS; for the defaults we
# assert it SUCCEEDS. Run from the repo root: ./hack/test-schema.sh
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

fails=0

# assert_reject <chart> <description> <helm --set args...>
assert_reject() {
  local chart="$1" desc="$2"; shift 2
  if helm template t "charts/$chart" "$@" >/dev/null 2>&1; then
    echo "  ✗ FAIL: [$chart] schema accepted invalid value ($desc)"
    fails=$((fails + 1))
  else
    echo "  ✓ rejected: [$chart] $desc"
  fi
}

# assert_accept <chart>  (defaults must validate)
assert_accept() {
  local chart="$1"
  if helm template t "charts/$chart" >/dev/null 2>&1; then
    echo "  ✓ accepted: [$chart] default values"
  else
    echo "  ✗ FAIL: [$chart] default values rejected by schema"
    fails=$((fails + 1))
  fi
}

echo "Building umbrella chart dependencies..."
helm dependency build charts/hatchet-stack >/dev/null
helm dependency build charts/hatchet-ha >/dev/null

echo "hatchet-api:"
assert_accept hatchet-api
assert_reject hatchet-api "replicaCount not an integer"      --set replicaCount=notanumber
assert_reject hatchet-api "image.pullPolicy not in enum"     --set image.pullPolicy=Bogus
assert_reject hatchet-api "service.type not in enum"         --set service.type=Sideways
assert_reject hatchet-api "migrationJob.backoffLimit < 0"    --set migrationJob.backoffLimit=-1
assert_reject hatchet-api "setupJob.enabled not a boolean"   --set setupJob.enabled=maybe

echo "hatchet-frontend:"
assert_accept hatchet-frontend
assert_reject hatchet-frontend "replicaCount not an integer" --set replicaCount=lots
assert_reject hatchet-frontend "image.pullPolicy not in enum" --set image.pullPolicy=Bogus
assert_reject hatchet-frontend "service.type not in enum"    --set service.type=Sideways

echo "hatchet-stack:"
assert_accept hatchet-stack
assert_reject hatchet-stack "api.replicaCount not an integer" --set api.replicaCount=two
assert_reject hatchet-stack "sharedConfig.enabled not a boolean" --set sharedConfig.enabled=yes
assert_reject hatchet-stack "caddy.image.pullPolicy not in enum" --set caddy.image.pullPolicy=Bogus

echo "hatchet-ha:"
assert_accept hatchet-ha
assert_reject hatchet-ha "grpc.replicaCount not an integer"  --set grpc.replicaCount=two
assert_reject hatchet-ha "sharedConfig.enabled not a boolean" --set sharedConfig.enabled=yes
assert_reject hatchet-ha "scheduler.replicaCount < 0"        --set scheduler.replicaCount=-1

echo
if [ "$fails" -ne 0 ]; then
  echo "$fails schema assertion(s) failed."
  exit 1
fi
echo "All schema assertions passed."
