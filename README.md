# haderach-platform

Platform control plane for `haderach.ai`.

This repository owns shared hosting/routing/deploy orchestration and cross-app smoke checks.
Application implementation, app CI, and app-local tests live in separate app repositories (for example `card`, `stocks`, and future app repos).

## What this repo is responsible for

- Shared host and routing topology for `haderach.ai`.
- Promotion of app-published artifacts into deployable platform state.
- Environment deploy orchestration.
- Platform-level smoke checks across app routes.
- Security/indexing defaults.

## What this repo is not responsible for

- App business logic.
- Building app source from app repos.
- App unit/integration test suites.

## Repository layout

- `hosting/public/` - platform-hosted static root content (app artifacts extracted here at deploy time).
- `firebase.json` - hosting baseline and security/indexing defaults.
- `.github/workflows/deploy.yml` - deploy workflow (manual dispatch, WIF auth, artifact download, Firebase deploy).
- `docs/architecture.md` - ownership boundaries, release flow, deploy workflow, routing model.
- `docs/learnings.md` - reusable implementation patterns.
- `todo/todo.md` - work priorities and tracking.
- `infra/` - Terraform modules for GCP infrastructure.

```text
haderach-platform/
├── .cursor/
│   └── rules/
│       ├── architecture-pointer.mdc
│       ├── branch-safety-reminder.mdc
│       ├── pr-conventions.mdc
│       ├── repo-hygiene.mdc
│       └── todo-conventions.mdc
├── .github/
│   └── workflows/
│       └── deploy.yml
├── docs/
│   ├── architecture.md
│   └── learnings.md
├── hosting/
│   └── public/
│       ├── assets/
│       │   └── landing/
│       │       └── logo.svg
│       ├── index.html
│       └── robots.txt
├── infra/
│   └── (terraform modules)
├── todo/
│   └── todo.md
├── .firebaserc
├── .gitignore
├── firebase.json
└── README.md
```

## Local development

Prerequisites:

- Node.js + npm
- Firebase CLI

Run the hosting emulator:

```bash
firebase emulators:start --only hosting --project haderach-ai --config firebase.json
```

## App repo integration model

Each app repo publishes immutable artifacts + metadata manifest.
Platform reads that manifest and promotes a version per environment.

## Deploy workflow

The deploy workflow (`.github/workflows/deploy.yml`) is triggered manually via `workflow_dispatch`.

Inputs:

- `commit_sha`: the app commit SHA whose published artifacts to deploy.
- `target_env`: `staging` or `production`.

The workflow authenticates to GCP via Workload Identity Federation, downloads and verifies artifacts from `gs://haderach-app-artifacts/card/versions/<sha>/`, extracts them into `hosting/public/card/`, then runs `firebase deploy --only hosting`.

Required GitHub repository variables:

- `GCP_WORKLOAD_IDENTITY_PROVIDER`
- `GCP_SERVICE_ACCOUNT`
- `GCS_ARTIFACT_BUCKET`

See `docs/architecture.md` for full deploy flow details and GCP auth setup.

## Onboarded apps

| App ID | Route | Artifact Bucket Path |
|---|---|---|
| `card` | `/card/` | `card/versions/<sha>/` |
| `stocks` | `/stocks/` | N/A (Cloud Run) |

## Promotion/deploy model evolution

Current model is manual SHA dispatch. Planned evolution:

- **PR-promote**: version file checked into repo, merge triggers deploy (audit trail + rollback).
- **Event-driven**: app repo triggers platform via repository dispatch after artifact publish.
