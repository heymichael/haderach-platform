#!/usr/bin/env bash
#
# Fetch the latest published artifact SHA for one or all apps.
# Uses the app repo's latest main commit and verifies it exists in GCS.
#
# Usage:
#   ./scripts/latest-artifact-sha.sh          # all apps
#   ./scripts/latest-artifact-sha.sh card     # single app
#   ./scripts/latest-artifact-sha.sh stocks   # single app

set -eo pipefail

BUCKET="haderach-app-artifacts"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SITE_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"

APPS=("card" "stocks")

get_app_dir() {
  echo "${SITE_DIR}/$1"
}

fetch_latest() {
  local app_id="$1"
  local app_dir
  app_dir="$(get_app_dir "$app_id")"

  if [[ ! -d "$app_dir/.git" ]]; then
    echo "${app_id}: repo not found at ${app_dir}"
    return 1
  fi

  git -C "$app_dir" fetch origin main --quiet 2>/dev/null
  local sha
  sha=$(git -C "$app_dir" log -1 --format='%H' origin/main)

  if gcloud storage ls "gs://${BUCKET}/${app_id}/versions/${sha}/manifest.json" &>/dev/null; then
    echo "${app_id}: ${sha}"
  else
    echo "${app_id}: ${sha} (not yet published — workflow may still be running)"
  fi
}

if [[ $# -gt 0 ]]; then
  fetch_latest "$1"
else
  for app in "${APPS[@]}"; do
    fetch_latest "$app"
  done
fi
