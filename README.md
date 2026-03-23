# haderach-platform

Platform control plane for `haderach.ai`.

This repository owns shared hosting/routing/deploy orchestration and cross-app smoke checks.
Application implementation, app CI, and app-local tests live in separate app repositories (`card`, `stocks`, `vendors`, `agent`).

## What this repo is responsible for

- Shared host and routing topology for `haderach.ai`.
- Platform-level authentication and RBAC (sign-in page, Firestore user/role management).
- Promotion of app-published artifacts into deployable platform state.
- Environment deploy orchestration.
- Platform-level smoke checks across app routes.
- Security/indexing defaults.

## What this repo is not responsible for

- App business logic.
- Building app source from app repos.
- App unit/integration test suites.

## Repository layout

- `hosting/public/` - deploy-time-only; all content comes from app artifacts (only `.gitkeep` is committed).
- `firebase.json` - hosting baseline, rewrites, and security/indexing defaults.
- `firestore.rules` - Firestore security rules (users collection, vendors, allowlists).
- `.github/workflows/deploy.yml` - app deploy workflow (manual dispatch, WIF auth, artifact download, Firebase deploy).
- `.github/workflows/redeploy-all.yml` - reconstructs full hosting state from latest-deployed markers and redeploys.
- `scripts/latest-artifact-sha.sh` - fetch latest published artifact SHA for one or all apps.
- `scripts/seed-users.py` - seed Firestore `users` collection with RBAC role assignments.
- `scripts/seed-allowlists.py` - seed Firestore `allowlists` collection (legacy).
- `docs/architecture.md` - ownership boundaries, release flow, deploy workflow, routing model, auth/RBAC.
- `tasks/` - per-task markdown files managed by [taskmd](https://github.com/driangle/taskmd).
- `infra/` - Terraform modules for GCP infrastructure.

```text
haderach-platform/
├── .cursor/
│   ├── rules/
│   │   ├── architecture-pointer.mdc
│   │   ├── branch-safety-reminder.mdc
│   │   ├── pr-conventions.mdc
│   │   ├── repo-hygiene.mdc
│   │   └── todo-conventions.mdc
│   └── skills/
│       └── fetch-artifact-sha/
│           └── SKILL.md
├── .github/
│   ├── pull_request_template.md
│   └── workflows/
│       ├── deploy.yml
│       └── redeploy-all.yml
├── docs/
│   └── architecture.md
├── hosting/
│   └── public/
│       └── .gitkeep          # deploy-time-only; all content from app artifacts
├── infra/
│   └── (terraform modules)
├── scripts/
│   ├── latest-artifact-sha.sh
│   ├── seed-allowlists.py
│   └── seed-users.py
├── tasks/
│   └── *.md (one file per task, managed by taskmd)
├── .firebaserc
├── .gitignore
├── .taskmd.yaml
├── firebase.json
├── firestore.rules
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

- `app_id`: which app to deploy (`home`, `card`, `stocks`, or `vendors`).
- `commit_sha`: the app commit SHA whose published artifacts to deploy.
- `target_env`: `staging` or `production`.

The workflow authenticates to GCP via Workload Identity Federation, downloads and verifies artifacts from `gs://haderach-app-artifacts/<app_id>/versions/<sha>/`, extracts them into `hosting/public/<app_id>/` (home extracts at root level), restores all other apps from their latest-deployed markers, then runs `firebase deploy --only hosting`.

Required GitHub repository variables:

- `GCP_WORKLOAD_IDENTITY_PROVIDER`
- `GCP_SERVICE_ACCOUNT`
- `GCS_ARTIFACT_BUCKET`

See `docs/architecture.md` for full deploy flow details and GCP auth setup.

## Onboarded apps

| App ID | Route | Artifact Bucket Path |
|---|---|---|
| `home` | `/` | `home/versions/<sha>/` |
| `card` | `/card/` | `card/versions/<sha>/` |
| `stocks` | `/stocks/` | `stocks/versions/<sha>/` |
| `vendors` | `/vendors/` | `vendors/versions/<sha>/` |

## Promotion/deploy model evolution

Current model is manual SHA dispatch. Planned evolution:

- **PR-promote**: version file checked into repo, merge triggers deploy (audit trail + rollback).
- **Event-driven**: app repo triggers platform via repository dispatch after artifact publish.
