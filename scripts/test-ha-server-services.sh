#!/usr/bin/env bash
# Guards against a regression where SERVER_SERVICES is dropped from the hatchet-ha
# chart. The engine splits into three roles (grpc-api, controllers, scheduler) and
# each deployment must pin its role via SERVER_SERVICES, otherwise every replica
# boots every service. We render the chart and assert each deployment's container
# carries the expected value. Run from the repo root: ./scripts/test-ha-server-services.sh
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

echo "Building hatchet-ha chart dependencies..."
helm dependency build charts/hatchet-ha >/dev/null

rendered="$(helm template t charts/hatchet-ha 2>/dev/null)"
if [ -z "$rendered" ]; then
  echo "  ✗ FAIL: helm template produced no output"
  exit 1
fi

# Extract (container-name, SERVER_SERVICES value) pairs from the rendered manifests.
# Container entries live at a 6-space indent under containers:; SERVER_SERVICES is an
# env entry two levels deeper, so its value belongs to the most recent container.
pairs="$(printf '%s\n' "$rendered" | awk '
  /^      - name: / { container = $3; gsub(/"/, "", container) }
  /^        - name: "SERVER_SERVICES"/ { want = 1; next }
  want && /^          value:/ { val = $2; gsub(/"/, "", val); print container, val; want = 0 }
')"

# expected container-name -> SERVER_SERVICES value (kept portable for bash 3.2)
expected_for() {
  case "$1" in
    grpc)        echo "grpc-api" ;;
    controllers) echo "controllers" ;;
    scheduler)   echo "scheduler" ;;
  esac
}

fails=0
for svc in grpc controllers scheduler; do
  want="$(expected_for "$svc")"
  got="$(printf '%s\n' "$pairs" | awk -v s="$svc" '$1 == s { print $2 }')"
  if [ -z "$got" ]; then
    echo "  ✗ FAIL: [$svc] no SERVER_SERVICES env rendered"
    fails=$((fails + 1))
  elif [ "$got" != "$want" ]; then
    echo "  ✗ FAIL: [$svc] SERVER_SERVICES is \"$got\", expected \"$want\""
    fails=$((fails + 1))
  else
    echo "  ✓ [$svc] SERVER_SERVICES=\"$got\""
  fi
done

echo
if [ "$fails" -ne 0 ]; then
  echo "$fails SERVER_SERVICES assertion(s) failed."
  exit 1
fi
echo "All SERVER_SERVICES assertions passed."
