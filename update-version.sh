#!/usr/bin/env bash

set -euo pipefail

if [[ "$OSTYPE" == "darwin"* ]]; then
  SED_INPLACE="sed -i.bak"
else
  # Linux and others
  SED_INPLACE="sed -i"
fi

function update_version() {
  RAW_TAG="$1"
  if ! echo "$RAW_TAG" | grep -qE '^v[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9\-\.]+)?$'; then
    echo "Invalid release tag format: $RAW_TAG" >&2
    exit 1
  fi
  RELEASE_TAG="$RAW_TAG"
  VERSION_NUMBER="${RELEASE_TAG#v}"

  echo "Updating charts to use release tag: $RELEASE_TAG (version: $VERSION_NUMBER)"

  find . -name "values.yaml" -type f | while read -r file; do
    echo "Processing values file: $file"
    $SED_INPLACE "s/tag: \"v[^\"]*\"/tag: \"$RELEASE_TAG\"/" "$file"
    $SED_INPLACE "s/tag: v[^[:space:]]*/tag: $RELEASE_TAG/" "$file"
  done

  find . -name "Chart.yaml" -type f | while read -r file; do
    echo "Processing Chart file: $file"
    $SED_INPLACE "s/^version: .*/version: $VERSION_NUMBER/" "$file"
    $SED_INPLACE '/name: "hatchet-api"/,/version:/ s/version: "[^"]*"/version: "'"$VERSION_NUMBER"'"/' "$file"
    $SED_INPLACE '/name: "hatchet-frontend"/,/version:/ s/version: "[^"]*"/version: "'"$VERSION_NUMBER"'"/' "$file"
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

# usage: ./update-version.sh <version>
if [ $# -ne 1 ]; then
  echo "Usage: $0 <version>"
  exit 1
fi

update_version "$1"
