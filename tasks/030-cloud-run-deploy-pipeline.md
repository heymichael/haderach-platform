---
id: "030"
title: "Add Cloud Run deploy pipeline for stocks-api"
status: completed
group: stocks
phase: stocks
priority: high
type: feature
tags: [ci, deploy, cloud-run, docker]
dependencies: ["010"]
effort: medium
created: 2026-03-18
---

# Add Cloud Run deploy pipeline for stocks-api

## Purpose

The stocks-api Cloud Run service (FastAPI backend) currently requires manual Docker build, push, and deploy steps. The SPA frontend now has an automated publish pipeline (task #010), but backend changes still require manual intervention. This creates deployment friction and risk of forgetting steps.

## Approach

### Option A: GitHub Actions workflow in stocks repo

Add a `.github/workflows/deploy-service.yml` that on push to `main` (when `service/**` files change):

1. Runs pre-deploy checks (lint, tests) against `service/`
2. Builds the Docker image from `service/Dockerfile` (linux/amd64)
3. Pushes to Artifact Registry (`us-central1-docker.pkg.dev/haderach-ai/haderach-apps/stocks-api`)
4. Deploys a new Cloud Run revision via `gcloud run deploy`
5. Runs a post-deploy health check against the live `/stocks/api/health` endpoint

Requires:
- WIF binding for the stocks repo SA to have Cloud Run deploy permissions
- Artifact Registry writer permissions for the SA
- Path filter so the workflow only runs when `service/` files change (not on SPA-only changes)

### Option B: Platform-orchestrated deploy

Similar to the SPA deploy, have the platform repo orchestrate Cloud Run deployments via `workflow_dispatch`.

### Pre-deploy testing

At minimum, the pipeline should gate on:
- **Linting** — ruff or flake8 against `service/`
- **Unit tests** — pytest with `httpx.AsyncClient` testing the FastAPI endpoints (mock the upstream Massive API). These don't exist yet and should be created as part of this task.
- **Docker build** — the image must build successfully before pushing

Post-deploy, the pipeline should verify the new revision is healthy before considering the deploy successful.

### Acceptance Criteria

- Backend changes to `service/` trigger an automated build and deploy
- The SPA publish workflow does NOT trigger a Cloud Run deploy (path filtering)
- Pre-deploy: lint + unit tests must pass before image push
- Post-deploy: health check confirms the new revision is serving
- Build targets `linux/amd64` (Cloud Run requirement)
- Rollback path is documented
