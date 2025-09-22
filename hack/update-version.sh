#!/usr/bin/env bash

set -euo pipefail

if [[ "$OSTYPE" == "darwin"* ]]; then
  SED_INPLACE="sed -i.bak"
else
  # Linux and others
  SED_INPLACE="sed -i"
fi

function update_image_tags() {
  RAW_TAG="$1"
  if ! echo "$RAW_TAG" | grep -qE '^v[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9\-\.]+)?$'; then
    echo "Invalid release tag format: $RAW_TAG" >&2
    exit 1
  fi
  RELEASE_TAG="$RAW_TAG"

  echo "Updating image tags to: $RELEASE_TAG"

  find . -name "values.yaml" -type f | while read -r file; do
    echo "Processing values file: $file"
    $SED_INPLACE "s/tag: \"v[^\"]*\"/tag: \"$RELEASE_TAG\"/" "$file"
    $SED_INPLACE "s/tag: v[^[:space:]]*/tag: $RELEASE_TAG/" "$file"
  done

  # Clean up backup files created by sed on macOS
  if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Cleaning up backup files..."
    find . -name "*.bak" -type f -delete
  fi

  echo "Image tag updates complete."
}

function update_chart_versions() {
  CHART_VERSION="$1"
  if ! echo "$CHART_VERSION" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9\-\.]+)?$'; then
    echo "Invalid chart version format: $CHART_VERSION" >&2
    exit 1
  fi

  echo "Updating chart versions to: $CHART_VERSION"

  find . -name "Chart.yaml" -type f | while read -r file; do
    echo "Processing Chart file: $file"
    $SED_INPLACE "s/^version: .*/version: $CHART_VERSION/" "$file"
    $SED_INPLACE '/name: "hatchet-api"/,/version:/ s/version: "[^"]*"/version: "'"$CHART_VERSION"'"/' "$file"
    $SED_INPLACE '/name: "hatchet-frontend"/,/version:/ s/version: "[^"]*"/version: "'"$CHART_VERSION"'"/' "$file"
  done

  find . -name "Chart.lock" -type f | while read -r file; do
    echo "Removing Chart.lock file: $file"
    rm "$file"
  done

  find . -name "Chart.yaml" -type f | while read -r file; do
    chart_dir=$(dirname "$file")
    if grep -q "dependencies:" "$file"; then
      echo "Running helm dependency update in: $chart_dir"
      (cd "$chart_dir" && helm dependency update)
    fi
  done

  # Clean up backup files created by sed on macOS
  if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Cleaning up backup files..."
    find . -name "*.bak" -type f -delete
  fi

  echo "Chart version updates and dependency updates complete."
}

function show_usage() {
  echo "Usage:"
  echo "  $0 image-tags <version>    # Update image tags (e.g., v0.71.0)"
  echo "  $0 chart-versions <version> # Update chart versions (e.g., 0.10.0)"
  echo ""
  echo "Examples:"
  echo "  $0 image-tags v0.72.0      # Updates all image tags to v0.72.0"
  echo "  $0 chart-versions 0.10.0   # Updates all chart versions to 0.10.0"
}

# Main script logic
if [ $# -ne 2 ]; then
  show_usage
  exit 1
fi

ACTION="$1"
VERSION="$2"

case "$ACTION" in
  "image-tags")
    update_image_tags "$VERSION"
    ;;
  "chart-versions")
    update_chart_versions "$VERSION"
    ;;
  *)
    echo "Error: Unknown action '$ACTION'"
    echo ""
    show_usage
    exit 1
    ;;
esac
