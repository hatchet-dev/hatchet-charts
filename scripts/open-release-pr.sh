#!/usr/bin/env bash

# Commit the chart changes, push the release branch and open a pull request
# requesting review from the hatchet-dev/builders team.
#
# Expects RELEASE_TAG, CHART_VERSION and RELEASE_BRANCH in the environment
# (see prepare-release.sh) and an authenticated `gh` CLI (GH_TOKEN).

set -euo pipefail

: "${RELEASE_TAG:?RELEASE_TAG must be set}"
: "${CHART_VERSION:?CHART_VERSION must be set}"
: "${RELEASE_BRANCH:?RELEASE_BRANCH must be set}"

git config user.name "${GITHUB_ACTOR:-github-actions}"
git config user.email "${GITHUB_ACTOR:-github-actions}@users.noreply.github.com"

if git diff --quiet; then
  echo "No changes to commit; skipping pull request"
  exit 0
fi

git add .
git commit -m "Release ${CHART_VERSION}: update charts to ${RELEASE_TAG}"
git push -u origin "$RELEASE_BRANCH"

gh pr create \
  --base main \
  --head "$RELEASE_BRANCH" \
  --title "Release ${CHART_VERSION}: update charts to ${RELEASE_TAG}" \
  --body "Automated chart release.

- Bumps chart versions to \`${CHART_VERSION}\`
- Updates Hatchet image tags to \`${RELEASE_TAG}\`" \
  --reviewer hatchet-dev/builders
