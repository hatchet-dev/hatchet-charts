#!/usr/bin/env bash

# Prepare a chart release: validate the Hatchet image tag, compute the next
# chart version (a minor bump) and the release branch name.
#
# Usage:
#   prepare-release.sh <hatchet-version>    # e.g. prepare-release.sh v0.84.0
#
# When run in GitHub Actions (GITHUB_ENV set) the computed values are exported
# as RELEASE_TAG, CHART_VERSION and RELEASE_BRANCH for later steps; otherwise
# they are just printed.

set -euo pipefail

if [ $# -ne 1 ]; then
  echo "Usage: $0 <hatchet-version>   # e.g. $0 v0.84.0" >&2
  exit 1
fi

RAW_TAG="$1"
if ! echo "$RAW_TAG" | grep -qE '^v[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9\-\.]+)?$'; then
  echo "Invalid release tag format: $RAW_TAG" >&2
  exit 1
fi
RELEASE_TAG="$RAW_TAG"

# The chart version is independent of the Hatchet app version and is bumped by
# one minor for every release (e.g. 0.11.0 -> 0.12.0).
CURRENT_VERSION=$(grep -m1 '^version:' charts/hatchet-stack/Chart.yaml | awk '{print $2}' | tr -d '"')
if ! echo "$CURRENT_VERSION" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
  echo "Could not parse current chart version: '$CURRENT_VERSION'" >&2
  exit 1
fi
IFS='.' read -r MAJOR MINOR _ <<< "$CURRENT_VERSION"
CHART_VERSION="${MAJOR}.$((MINOR + 1)).0"
RELEASE_BRANCH="release-${CHART_VERSION}"

echo "Hatchet image tag:     $RELEASE_TAG"
echo "Current chart version: $CURRENT_VERSION"
echo "New chart version:     $CHART_VERSION"
echo "Release branch:        $RELEASE_BRANCH"

if [ -n "${GITHUB_ENV:-}" ]; then
  {
    echo "RELEASE_TAG=$RELEASE_TAG"
    echo "CHART_VERSION=$CHART_VERSION"
    echo "RELEASE_BRANCH=$RELEASE_BRANCH"
  } >> "$GITHUB_ENV"
fi
