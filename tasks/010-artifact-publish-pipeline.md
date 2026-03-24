---
id: "10"
title: "Add artifact publish pipeline"
status: completed
group: stocks
phase: stocks
priority: high
type: feature
tags: [ci, deploy, gcs, artifacts]
effort: medium
created: 2026-03-17
---

# Add artifact publish pipeline

## Purpose

Stocks doesn't have its own artifact publish pipeline yet. Card already produces a `runtime.tar.gz` + `checksums.txt` + `manifest.json` and publishes them to GCS, where the platform deploy workflow picks them up. Stocks needs the same so it can be deployed through the same platform pipeline.

## Approach

### 1. Stocks repo — packaging and publish

- Add a `scripts/package-artifacts.sh` (or equivalent) to produce:
  - `runtime.tar.gz` — compressed build output
  - `checksums.txt` — SHA-256 checksum of the tarball
- Add a `scripts/generate-manifest.mjs` to produce `manifest.json` with `app_id: "stocks"`, commit SHA, runtime URI, checksum, and `platform_contract_version: "v1"`.
- Add a `publish-artifact.yml` GitHub Actions workflow that:
  - Builds the app
  - Runs `package-artifacts.sh` and `generate-manifest.mjs`
  - Authenticates to GCP via Workload Identity Federation
  - Uploads all three files to `gs://<bucket>/stocks/versions/<sha>/`

Use card's implementation as the reference:
- `card/scripts/package-artifacts.sh`
- `card/scripts/generate-manifest.mjs`
- `card/.github/workflows/publish-artifact.yml`

### 2. Platform deploy workflow — extend for stocks

- Update `haderach-platform/.github/workflows/deploy.yml` to support deploying stocks (in addition to card).
- Either parameterize the existing workflow with an `app_id` input, or add a separate stocks deploy workflow.
- Download and extract stocks artifacts into the correct hosting path (e.g. `hosting/public/stocks/`).
