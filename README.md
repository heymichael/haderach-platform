# haderach-platform

Platform control plane for `haderach.ai`.

This repository owns shared hosting/routing/deploy orchestration and cross-app smoke checks.
Application implementation, app CI, and app-local tests live in separate app repositories (`stocks`, `vendors`, `agent`).

## What this repo is responsible for

- Shared host and routing topology for `haderach.ai`.
- Platform-level authentication and RBAC (sign-in page, Postgres user/role management via agent service).
- Promotion of app-published artifacts into deployable platform state.
- Environment deploy orchestration.
- Content hosting infrastructure (`docs.haderach.ai` — authenticated static-file server).
- Platform-level smoke checks across app routes.
- Security/indexing defaults.

## What this repo is not responsible for

- App business logic.
- Building app source from app repos.
- App unit/integration test suites.

## Repository layout

- `hosting/public/` - deploy-time-only; all content comes from app artifacts (only `.gitkeep` is committed).
- `firebase.json` - hosting baseline, rewrites, and security/indexing defaults.
- `firestore.rules` - Firestore security rules (retained for home app direct reads).
- `.github/workflows/deploy.yml` - app deploy workflow (manual dispatch, WIF auth, artifact download, Firebase deploy).
- `.github/workflows/batch-deploy.yml` - deploy multiple app artifacts in a single Firebase Hosting deploy.
- `.github/workflows/redeploy-all.yml` - reconstructs full hosting state from latest-deployed markers and redeploys.
- `.github/workflows/deploy-content.yml` - sync `haderach-content` files to GCS bucket.
- `.github/workflows/deploy-content-api.yml` - build and deploy the `content-api` Cloud Run service.
- `services/content-api/` - authenticated static-file server for `docs.haderach.ai` (FastAPI + Google OAuth + GCS).
- `scripts/seed-users.py` - deprecated — see `agent/scripts/seed_users.py`.
- `docs/architecture.md` - ownership boundaries, release flow, deploy workflow, routing model, auth/RBAC.
- `infra/` - Terraform modules for GCP infrastructure (Cloud Run, Cloud SQL, Secret Manager, GCS, IAM, WIF).

```text
haderach-platform/
├── .cursor/
│   └── rules/
│       ├── architecture-pointer.mdc
│       ├── backend-auth-policy.mdc
│       ├── branch-safety-reminder.mdc
│       ├── cross-repo-status.mdc
│       ├── local-dev-testing.mdc
│       ├── pr-conventions.mdc
│       ├── repo-hygiene.mdc
│       ├── service-oriented-data-access.mdc
│       ├── todo-conventions.mdc
│       └── work-groups.mdc
├── .github/
│   ├── pull_request_template.md
│   └── workflows/
│       ├── batch-deploy.yml
│       ├── deploy.yml
│       ├── deploy-content.yml
│       ├── deploy-content-api.yml
│       └── redeploy-all.yml
├── docs/
│   └── architecture.md
├── hosting/
│   └── public/
│       └── .gitkeep          # deploy-time-only; all content from app artifacts
├── infra/
│   └── (terraform modules)
├── scripts/
│   └── seed-users.py
├── services/
│   └── content-api/
│       ├── Dockerfile
│       ├── app.py
│       └── requirements.txt
├── .firebaserc
├── .gitignore
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

- `app_id`: which app to deploy (`home`, `stocks`, `vendors`, `admin-system`, or `admin-vendors`).
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
| `stocks` | `/stocks/` | `stocks/versions/<sha>/` |
| `vendors` | `/vendors/` | `vendors/versions/<sha>/` |
| `admin-system` | `/admin/system/` | `admin-system/versions/<sha>/` |
| `admin-vendors` | `/admin/vendors/` | `admin-vendors/versions/<sha>/` |

## Related repos

| Repo | Relationship |
|---|---|
| `haderach-home` | Homepage SPA + shared-ui design system (served at `/`) |
| `stocks` | Stocks app (served at `/stocks/`) |
| `vendors` | Vendor management app (served at `/vendors/`) |
| `admin-system` | System admin app (served at `/admin/system/`) |
| `admin-vendors` | Vendor admin app (served at `/admin/vendors/`) |
| `agent` | Shared chat agent backend (Cloud Run at `/agent/api/`) |
| `haderach-content` | Static content source synced to GCS for `docs.haderach.ai` |
| `haderach-tasks` | Centralized task management (tasks, bugs, strategy records) |

## Promotion/deploy model evolution

Current model is manual SHA dispatch. Planned evolution:

- **PR-promote**: version file checked into repo, merge triggers deploy (audit trail + rollback).
- **Event-driven**: app repo triggers platform via repository dispatch after artifact publish.
