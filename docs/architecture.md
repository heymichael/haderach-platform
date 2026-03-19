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
│       ├── deploy.yml
│       └── deploy-platform.yml
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
│   └── (terraform modules, including firestore.tf)
├── scripts/
│   └── seed-allowlists.py
├── tasks/
│   └── (taskmd task files)
├── .firebaserc
├── .gitignore
├── firebase.json
├── firestore.rules
└── README.md
```

## Ownership Boundaries

### Platform repo owns

- Shared hosting and route topology for `haderach.ai`.
- Promotion decisions from app artifacts to deployed platform state.
- Environment deployment orchestration (staging/production).
- Cross-app smoke tests after deployment.
- Security defaults at host/platform level (headers, indexing defaults).
- Centralized allowlist data in Firestore (see [Allowlist Management](#allowlist-management)).

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

## Deploy Workflows

### App Deploy (`.github/workflows/deploy.yml`)

Deploys an app artifact to Firebase Hosting via manual dispatch.

#### Trigger

Manual dispatch (`workflow_dispatch`) with inputs:

- `app_id`: which app to deploy (`card` or `stocks`).
- `commit_sha`: the app commit SHA whose artifacts to deploy.
- `target_env`: `staging` or `production`.

#### Flow

1. Authenticate to GCP via Workload Identity Federation.
2. Download `manifest.json`, `runtime.tar.gz`, and `checksums.txt`
   from `gs://haderach-app-artifacts/<app_id>/versions/<commit_sha>/`.
3. Validate manifest (`app_id`, `platform_contract_version`, `commit_sha` match).
4. Verify SHA-256 checksums against `checksums.txt`.
5. Extract `runtime.tar.gz` into `hosting/public/<app_id>/`.
6. Restore all other onboarded apps from their latest deployed artifacts
   (reads `latest-deployed.json` markers from GCS; see below).
7. Run `firebase deploy --only hosting --project haderach-ai`.
8. Write a `latest-deployed.json` marker to GCS for the deployed app.

### Platform Hosting Deploy (`.github/workflows/deploy-platform.yml`)

Deploys platform-owned hosting assets (homepage, robots.txt, logo) independently
of any app artifact. Useful when platform assets change without an app deploy.

#### Trigger

Manual dispatch (`workflow_dispatch`) with one input:

- `target_env`: `staging` or `production`.

#### Flow

1. Check out `main` (gets current platform assets in `hosting/public/`).
2. Authenticate to GCP via Workload Identity Federation.
3. For each onboarded app, read its `latest-deployed.json` marker from GCS.
   If present, download and extract that version's `runtime.tar.gz` into
   `hosting/public/<app_id>/`.
4. Run `firebase deploy --only hosting --project haderach-ai`.

### GCS Deploy Markers

Because Firebase Hosting deploys are atomic (the entire `hosting/public/`
directory is replaced), each deploy must reconstruct the full hosted state.
Both workflows use GCS marker files to track which app version was last deployed:

```text
gs://haderach-app-artifacts/<app_id>/latest-deployed.json
```

```json
{ "commit_sha": "<sha>", "deployed_at": "<ISO-8601>" }
```

The app deploy workflow writes this marker after a successful deploy.
Both workflows read these markers to restore other apps' artifacts before deploying.

### GCP Authentication

- WIF pool: `projects/479571627322/locations/global/workloadIdentityPools/github-actions`
- WIF provider: `.../providers/github-actions`
- Service account: `haderach-platform-deployer@haderach-ai.iam.gserviceaccount.com`
- Roles: `Storage Object Viewer` and `Storage Object Creator` (artifact bucket), `Firebase Hosting Admin` (project).
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
| `card` | `/card/` | Deployed |
| `stocks` | `/stocks/` | Deployed |

## Smoke Test Ownership

Platform owns post-deploy smoke tests that validate:

- Route reachability for root and app runtime.
- Basic health signals (HTTP status, expected shell marker).
- Cross-app routing integrity (no collisions/regressions).

App repos own deep app behavior tests; platform only verifies deploy/routing health.

## Allowlist Management

User access to individual apps is controlled via a centralized allowlist stored in
Firestore, replacing the hardcoded email/domain arrays previously in each app's source.

### Firestore collection: `allowlists`

One document per app, keyed by app ID:

```text
allowlists/card     → surfaces.default.{emails, domains}
allowlists/stocks   → surfaces.default.{emails, domains}
```

Both apps use a single flat surface (`default`).

### How apps consume the allowlist

Each app's `accessPolicy.ts` fetches its allowlist document from Firestore at runtime
using the Firebase JS SDK. The fetch happens after Firebase Auth confirms the user's
identity but before granting access.

### Fail-closed behavior

If the Firestore read fails (network error, missing document, permission denied),
apps return an empty policy — all users are denied access until Firestore is reachable.

### Managing the allowlist

Edit documents directly in the [Firebase Console](https://console.firebase.google.com)
under the `haderach-ai` project → Firestore Database → `allowlists` collection.
Changes take effect immediately without app redeployment.

### Security rules

Defined in `firestore.rules` and deployed via `firebase deploy`:

- **Read**: any authenticated Firebase user (required so the auth gate can check the list).
- **Write**: denied from client SDKs. Admin writes go through the Firebase Console or
  Admin SDK scripts.

### Infrastructure

- Firestore Native mode is provisioned via `infra/firestore.tf`.
- Initial data was seeded using `scripts/seed-allowlists.py`.

## Security and Indexing Defaults

Default indexing policy is deny-by-default:

- Platform sets `X-Robots-Tag: noindex, nofollow, noarchive`.
- Individual app routes can be explicitly allowlisted by platform review.
- No public indexing by default until explicit approval.
