---
id: "53"
title: "Add batch-deploy workflow for multi-app promotion in a single Firebase deploy"
status: done
group: platform
phase: platform
priority: high
type: improvement
tags: [ci, deploy, firebase-hosting, workflow]
effort: medium
created: 2026-03-23
---

## Purpose

The current `deploy.yml` workflow deploys one app at a time. Each run restores all other apps from their `latest-deployed.json` markers and does a full `firebase deploy`. Promoting N apps requires N manual workflow dispatches and N redundant Firebase deploys, each re-downloading the other apps' artifacts.

A batch workflow would accept optional SHAs for each app, verify and assemble all artifacts in one run, and do a single `firebase deploy` — eliminating redundant work and manual back-and-forth.

## Approach

1. Create `batch-deploy.yml` with optional string inputs for each app SHA (`home_sha`, `card_sha`, `stocks_sha`, `vendors_sha`), a `deploy_all_latest` boolean, and a required `target_env` choice.
2. SHA resolution step: for each app, use the explicit SHA if provided, else look up the latest published artifact SHA if `deploy_all_latest` is true, else skip. An explicit SHA always overrides `deploy_all_latest` for that app.
3. Parallel verify jobs: for each resolved SHA, run a matrix job that downloads, validates the manifest, and verifies checksums.
4. Single deploy job (depends on all verify jobs): assemble `hosting/public/` by extracting requested app artifacts and restoring non-requested apps from their `latest-deployed.json` markers. Run one `firebase deploy --only hosting`.
5. Write `latest-deployed.json` markers for all newly deployed apps.
6. Keep the existing single-app `deploy.yml` as-is for quick single-app promotions.

## UX

```
workflow_dispatch inputs:
  deploy_all_latest: false          # deploy latest artifact for every app
  home_sha:    (optional)           # explicit SHA overrides deploy_all_latest
  card_sha:    (optional)
  stocks_sha:  (optional)
  vendors_sha: (optional)
  target_env:  staging | production
```

### Usage patterns

- **Deploy everything new:** check `deploy_all_latest`, leave all SHA fields blank.
- **Deploy specific apps only:** paste SHAs for the apps to promote, leave others blank.
- **Deploy all latest except pin one app:** check `deploy_all_latest`, paste an older SHA for the app to pin (explicit SHA overrides the auto-lookup).
- **Single app:** paste one SHA, leave the rest blank (or use the existing `deploy.yml`).
