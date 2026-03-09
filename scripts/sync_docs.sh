#!/usr/bin/env bash
# Sync platform docs sources into hosting/public/docs.
# Run from repo root.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

SRC="$ROOT/docs"
DST="$ROOT/hosting/public/docs"

if [[ ! -d "$SRC" ]]; then
  echo "Missing docs source directory: $SRC"
  exit 1
fi

mkdir -p "$DST"
rm -rf "$DST"/*
cp -R "$SRC"/. "$DST"/

echo "Synced docs -> hosting/public/docs"
