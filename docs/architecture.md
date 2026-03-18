# Architecture

## Purpose

`haderach-platform` is the deployment and routing control plane for `haderach.ai`.
It does not own app business logic. It owns shared hosting/routing/deployment orchestration and cross-app smoke checks.

## Repository Tree (ASCII)

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

## Ownership Boundaries

### Platform repo owns

- Shared hosting and route topology for `haderach.ai`.
- Promotion decisions from app artifacts to deployed platform state.
- Environment deployment orchestration (staging/production).
- Cross-app smoke tests after deployment.
- Security defaults at host/platform level (headers, indexing defaults).

### App repos own

- App implementation and runtime behavior.
- App CI (build, unit/integration tests, app-level checks).
- App release artifact production and metadata publication.

## Release Flow

Canonical flow:

1. App feature branch
2. App PR CI
3. Merge app `main`
4. App artifact/version publish
5. Platform promotion (select artifact version for an environment)
6. Platform deploy
7. Platform smoke checks

The platform never builds app source directly; it consumes app-published artifacts.

## Routing Model

### Root

- `haderach.ai/`
- Platform landing/status page.

### App runtime

- `haderach.ai/<app>/`
- Served from promoted artifact for that app ID.

Route names are stable platform-facing identifiers and are decoupled from app repository names.

## Deploy Workflow

The platform deploys app artifacts to Firebase Hosting via a manually-triggered
GitHub Actions workflow (`.github/workflows/deploy.yml`).

### Trigger

Manual dispatch (`workflow_dispatch`) with two inputs:

- `commit_sha`: the app commit SHA whose artifacts to deploy.
- `target_env`: `staging` or `production`.

### Flow

1. Authenticate to GCP via Workload Identity Federation.
2. Download `manifest.json`, `runtime.tar.gz`, and `checksums.txt`
   from `gs://haderach-app-artifacts/card/versions/<commit_sha>/`.
3. Validate manifest (`app_id`, `platform_contract_version`, `commit_sha` match).
4. Verify SHA-256 checksums against `checksums.txt`.
5. Extract `runtime.tar.gz` into `hosting/public/card/`.
6. Run `firebase deploy --only hosting --project haderach-ai`.

### GCP Authentication

- WIF pool: `projects/479571627322/locations/global/workloadIdentityPools/github-actions`
- WIF provider: `.../providers/github-actions`
- Service account: `haderach-platform-deployer@haderach-ai.iam.gserviceaccount.com`
- Roles: `Storage Object Viewer` (artifact bucket), `Firebase Hosting Admin` (project).
- Trust condition scoped to `heymichael/haderach-platform`.

### Required GitHub repository variables

| Variable | Purpose |
|---|---|
| `GCP_WORKLOAD_IDENTITY_PROVIDER` | WIF provider resource name |
| `GCP_SERVICE_ACCOUNT` | GCP service account for deploy |
| `GCS_ARTIFACT_BUCKET` | GCS bucket name (`haderach-app-artifacts`) |

### Future evolution

Current model is manual SHA dispatch. Planned evolution toward PR-promote
(version file checked into repo, merge triggers deploy) or event-driven
(card repo triggers platform via repository dispatch).

## Deployment Contract for App Repos

Each app repo must publish immutable versioned artifacts plus metadata.

### Artifact format

- Runtime artifact: `runtime.tar.gz` — static bundle suitable for hosting at `/<route_prefix>/`.
- Checksums: `checksums.txt` — SHA-256 checksum for the tarball.
- Metadata: `manifest.json` — machine-readable version and artifact metadata.

### GCS artifact paths

Immutable versioned artifacts are stored at:

```text
gs://haderach-app-artifacts/<app_id>/versions/<commit-sha>/
  runtime.tar.gz
  checksums.txt
  manifest.json
```

### Required metadata (example shape)

```json
{
  "app_id": "card",
  "version": "1.2.3+build.45",
  "commit_sha": "abc123...",
  "published_at": "2026-03-05T12:00:00Z",
  "artifact": {
    "runtime_uri": "gs://haderach-app-artifacts/card/versions/abc123.../runtime.tar.gz",
    "checksum_sha256": "..."
  },
  "compatibility": {
    "platform_contract_version": "v1"
  }
}
```

Platform consumes metadata and promotes specific versions by environment.

## Onboarded Apps

| App ID | Route prefix | Status |
|---|---|---|
| `card` | `/card/` | First deploy |

## Smoke Test Ownership

Platform owns post-deploy smoke tests that validate:

- Route reachability for root and app runtime.
- Basic health signals (HTTP status, expected shell marker).
- Cross-app routing integrity (no collisions/regressions).

App repos own deep app behavior tests; platform only verifies deploy/routing health.

## Security and Indexing Defaults

Default indexing policy is deny-by-default:

- Platform sets `X-Robots-Tag: noindex, nofollow, noarchive`.
- Individual app routes can be explicitly allowlisted by platform review.
- No public indexing by default until explicit approval.
