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
│   ├── index.html
│   ├── architecture.md
│   ├── architecture.html
│   ├── app-registry.example.json
│   ├── artifact-manifest.schema.json
│   ├── artifact-manifest.example.json
│   ├── priorities/
│   │   └── index.html
│   ├── requirements/
│   │   ├── catalog.json
│   │   └── projects/
│   │       └── requirements-project.template.html
│   ├── test-status/
│   │   ├── catalog.json
│   │   ├── checks/
│   │   │   ├── deploy-smoke-artifact-checks.html
│   │   │   ├── deploy-smoke-contract-checks.html
│   │   │   ├── nightly-e2e-regression-artifact-checks.html
│   │   │   ├── nightly-e2e-regression-contract-checks.html
│   │   │   ├── prod-monitor-artifact-checks.html
│   │   │   └── prod-monitor-contract-checks.html
│   │   ├── reports/
│   │       ├── deploy-smoke.html
│   │       ├── nightly-e2e-regression.html
│   │       └── prod-monitor.html
│   │   └── summaries/
│   │       ├── deploy-smoke-summary.json
│   │       ├── nightly-e2e-regression-summary.json
│   │       └── prod-monitor-summary.json
│   ├── testing/
│   │   ├── catalog.json
│   │   ├── test-lineup.html
│   │   └── testing-infrastructure.html
│   └── shared/
│       ├── docs-shell.css
│       ├── docs-shell-page.template.html
│       └── docs-shell.js
├── hosting/
│   └── public/
│       ├── assets/
│       │   └── landing/
│       │       └── logo.svg
│       ├── index.html
│       └── robots.txt
├── scripts/
│   ├── generate_docs_pages.py
│   ├── requirements-docs.txt
│   └── sync_docs.sh
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
- App-local docs generation.

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
- Platform landing/status page (or future shared portal shell).

### Root docs

- `haderach.ai/docs/`
- Platform-level docs hub/shell route.
- Implemented with shared docs-shell assets to keep UX consistent with app docs surfaces.

### App runtime

- `haderach.ai/<app>/`
- Served from promoted artifact for that app ID.

### App docs

- `haderach.ai/<app>/docs/`
- Served from promoted docs artifact path for that app ID.
- App repos should reuse the same docs-shell files/patterns used by platform docs for consistent tabs/layout.

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
2. Download `manifest.json`, `runtime.tar.gz`, `docs.tar.gz`, and `checksums.txt`
   from `gs://haderach-app-artifacts/card/versions/<commit_sha>/`.
3. Validate manifest (`app_id`, `platform_contract_version`, `commit_sha` match).
4. Verify SHA-256 checksums against `checksums.txt`.
5. Extract `runtime.tar.gz` into `hosting/public/card/`.
6. Extract `docs.tar.gz` into `hosting/public/card/docs/`.
7. Run `firebase deploy --only hosting --project haderach-ai`.

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

### Auth injection

Not required. App and docs artifacts ship with auth config baked in at build time.
The platform extracts and serves without modification.

### Future evolution

Current model is manual SHA dispatch. Planned evolution toward PR-promote
(version file checked into repo, merge triggers deploy) or event-driven
(card repo triggers platform via repository dispatch).

## Deployment Contract for App Repos

Each app repo must publish immutable versioned artifacts plus metadata.

### Artifact format (minimal baseline)

- Runtime artifact: `runtime.tar.gz` — static bundle suitable for hosting at `/<route_prefix>/`.
- Docs artifact: `docs.tar.gz` — static docs site suitable for hosting at `/<route_prefix>/docs/`.
- Checksums: `checksums.txt` — SHA-256 checksums for both tarballs.
- Metadata: `manifest.json` — machine-readable version and artifact metadata.

### GCS artifact paths

Immutable versioned artifacts are stored at:

```text
gs://haderach-app-artifacts/<app_id>/versions/<commit-sha>/
  runtime.tar.gz
  docs.tar.gz
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
    "docs_uri": "gs://haderach-app-artifacts/card/versions/abc123.../docs.tar.gz",
    "checksum_sha256": "..."
  },
  "compatibility": {
    "platform_contract_version": "v1"
  }
}
```

See `docs/artifact-manifest.schema.json` for the canonical machine-readable schema.

Platform consumes metadata and promotes specific versions by environment.

## App Registry Contract

Registry lives at `docs/app-registry.example.json` (template).
Fields intentionally decouple route naming from repository naming.

- `app_id`: stable platform identifier.
- `route_prefix`: URL segment used at `haderach.ai/<route_prefix>/`.
- `artifact_source`: where platform discovers published metadata/artifacts.
- `docs_route`: explicit docs route (normally `/<route_prefix>/docs/`).

### Onboarded apps

| App ID | Route prefix | Docs route | Status |
|---|---|---|---|
| `card` | `/card/` | `/card/docs/` | First deploy |

## Smoke Test Ownership

Platform owns post-deploy smoke tests that validate:

- Route reachability for root, app runtime, and app docs.
- Basic health signals (HTTP status, expected shell marker).
- Cross-app routing integrity (no collisions/regressions).

App repos own deep app behavior tests; platform only verifies deploy/routing health.

## Security and Indexing Defaults

Default indexing policy is deny-by-default:

- Platform sets `X-Robots-Tag: noindex, nofollow, noarchive`.
- Individual app/docs routes can be explicitly allowlisted by platform review.
- No public indexing by default until explicit approval.

Additional baseline host headers should remain centrally managed in platform config.

## Local Parity Prep

For local Hosting parity around platform docs/priorities:

1. Generate docs from `todo/todo.md` via `python3 scripts/generate_docs_pages.py`.
2. Sync `docs/` into `hosting/public/docs/` via `bash scripts/sync_docs.sh`.
3. Run Hosting emulator from repo root:
   `firebase emulators:start --only hosting --project haderach-ai --config firebase.json`.

## Docs UX Reuse Contract

For consistent docs UI across platform and apps:

- Canonical shell assets live in `docs/shared/docs-shell.css` and `docs/shared/docs-shell.js`.
- Platform page at `docs/index.html` uses those shared assets for `/docs`.
- App repos should use the same markup pattern (template: `docs/shared/docs-shell-page.template.html`) and only customize app-specific labels, route base path, and tab sources.

For requirements docs, use the same source->served contract used by priorities:

- Authoring source of truth: `docs/requirements/projects/*.html` and `docs/requirements/catalog.json`.
- Served/deploy copy after sync: `hosting/public/docs/requirements/projects/*.html` and `hosting/public/docs/requirements/catalog.json`.
- Canonical project template: `docs/requirements/projects/requirements-project.template.html`.
