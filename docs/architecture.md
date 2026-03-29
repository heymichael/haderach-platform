# Architecture

## Purpose

`haderach-platform` is the deployment and routing control plane for `haderach.ai`.
It does not own app business logic. It owns shared hosting/routing/deployment orchestration and cross-app smoke checks.

## Repository Tree (ASCII)

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
│       ├── batch-deploy.yml
│       ├── deploy.yml
│       └── redeploy-all.yml
├── docs/
│   └── architecture.md
├── hosting/
│   └── public/
│       └── .gitkeep          # deploy-time-only; all content from app artifacts
├── infra/
│   └── (terraform modules, including firestore.tf)
├── scripts/
│   ├── latest-artifact-sha.sh
│   ├── seed-allowlists.py
│   └── seed-users.py
├── tasks/
│   └── (taskmd task files)
├── .firebaserc
├── .gitignore
├── .taskmd.yaml
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
- Platform-level authentication and RBAC (see [Authentication & RBAC](#authentication--rbac)).

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
- Served from the `home` app artifact (haderach-home repo).

### App runtime

- `haderach.ai/<app>/`
- Served from promoted artifact for that app ID.

Route names are stable platform-facing identifiers and are decoupled from app repository names.

## Deploy Workflows

### App Deploy (`.github/workflows/deploy.yml`)

Deploys an app artifact to Firebase Hosting via manual dispatch.

#### Trigger

Manual dispatch (`workflow_dispatch`) with inputs:

- `app_id`: which app to deploy (`home`, `card`, `stocks`, or `vendors`).
- `commit_sha`: the app commit SHA whose artifacts to deploy.
- `target_env`: `staging` or `production`.

#### Flow

1. Authenticate to GCP via Workload Identity Federation.
2. Download `manifest.json`, `runtime.tar.gz`, and `checksums.txt`
   from `gs://haderach-app-artifacts/<app_id>/versions/<commit_sha>/`.
3. Validate manifest (`app_id`, `platform_contract_version`, `commit_sha` match).
4. Verify SHA-256 checksums against `checksums.txt`.
5. Extract `runtime.tar.gz` into `hosting/public/` (home extracts at root level;
   other apps extract into `hosting/public/<app_id>/`).
6. Restore all other onboarded apps from their latest deployed artifacts
   (reads `latest-deployed.json` markers from GCS; see below).
7. Run `firebase deploy --only hosting --project haderach-ai`.
8. Write a `latest-deployed.json` marker to GCS for the deployed app.

### Batch Deploy (`.github/workflows/batch-deploy.yml`)

Deploys multiple app artifacts in a single Firebase Hosting deploy via manual
dispatch. Verifies each artifact in parallel, assembles the full hosting state
once, and does one atomic deploy.

#### Trigger

Manual dispatch (`workflow_dispatch`) with inputs:

- `deploy_all_latest`: boolean — resolve latest main SHA for all apps automatically.
- `home_sha`, `card_sha`, `stocks_sha`, `vendors_sha`: optional per-app SHAs.
  Explicit SHA always overrides `deploy_all_latest` for that app.
- `target_env`: `staging` or `production`.

#### Flow

1. **Resolve**: for each app, use explicit SHA if provided, else look up latest
   main SHA via GitHub API (requires `CROSS_REPO_PAT` secret) if
   `deploy_all_latest` is true, else skip. Verify each resolved artifact exists
   in GCS.
2. **Verify** (parallel matrix): download, validate manifest, and verify checksums
   for each resolved app artifact.
3. **Deploy**: extract all verified artifacts into `hosting/public/`, restore
   non-deployed apps from `latest-deployed.json` markers, run one
   `firebase deploy`, and write updated markers for all deployed apps.

#### Usage patterns

- **Deploy everything new**: check `deploy_all_latest`, leave SHA fields blank.
- **Deploy specific apps**: paste SHAs for the apps to promote, leave others blank.
- **Deploy all latest except pin one app**: check `deploy_all_latest`, paste an
  older SHA for the app to pin.

#### Required secrets

| Secret | Purpose |
|---|---|
| `CROSS_REPO_PAT` | GitHub PAT with read access to app repos (only needed for `deploy_all_latest`) |

### Redeploy All (`.github/workflows/redeploy-all.yml`)

Reconstructs the full hosting state from latest-deployed artifact markers and
redeploys. No new app versions are deployed — this uses whatever each app last
deployed. Useful for applying `firebase.json` config changes (headers, rewrites)
or performing a clean rebuild of the hosting state.

#### Trigger

Manual dispatch (`workflow_dispatch`) with one input:

- `target_env`: `staging` or `production`.

#### Flow

1. Authenticate to GCP via Workload Identity Federation.
2. For each onboarded app, read its `latest-deployed.json` marker from GCS.
   If present, download and extract that version's `runtime.tar.gz` into
   `hosting/public/`.
3. Run `firebase deploy --only hosting --project haderach-ai`.

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
  The `home` app is a special case: its tarball contains root-level files (not nested
  under a subdirectory) because it is served at `/`.
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

| App ID | Route prefix | Repo | Status |
|---|---|---|---|
| `home` | `/` | `haderach-home` | Deployed |
| `card` | `/card/` | `card` | Deployed |
| `stocks` | `/stocks/` | `stocks` | Deployed |
| `vendors` | `/vendors/` | `vendors` | Deployed |
| `admin-system` | `/admin/system/` | `admin-system` | Deployed |

## Backend Services (Cloud Run)

| Service | Route | Repo | Purpose |
|---|---|---|---|
| `vendors-api` | `/vendors/api/**` | `vendors` | Vendor spend data (AWS billing) |
| `stocks-api` | `/stocks/api/**` | `stocks` | Stock market data (Massive API) |
| `agent-api` | `/agent/api/**` | `agent` | Shared chat agent (OpenAI tool-calling, Firestore CRUD) |

All backend services run on Cloud Run (us-central1) and are fronted by Firebase
Hosting rewrites. The default compute service account is used at runtime; each
service's secrets are injected via Secret Manager env var mounts.

## Smoke Test Ownership

Platform owns post-deploy smoke tests that validate:

- Route reachability for root and app runtime.
- Basic health signals (HTTP status, expected shell marker).
- Cross-app routing integrity (no collisions/regressions).

App repos own deep app behavior tests; platform only verifies deploy/routing health.

## Authentication & RBAC

Authentication is centralized at the platform level. Users sign in once at
`haderach.ai/` and the session carries across all app routes on the same origin.

### Sign-in flow

1. User navigates to an app route (e.g., `/card/`).
2. App's `AuthGate` checks for an existing Firebase Auth session (shared via
   same-origin IndexedDB persistence).
3. If no session exists:
   - **Production**: the app redirects to `/?returnTo=/card/`.
   - **Local dev** (`import.meta.env.DEV`): the app shows a dev-only "Sign in
     with Google" button, allowing authentication directly on the app's origin
     without requiring haderach-home to be running.
4. The home app (`haderach-home`, served at `/`) handles Google sign-in
   via Firebase Auth (production flow).
5. After sign-in, the app calls `fetchUserDoc` (from `@haderach/shared-ui`) which
   hits `GET /agent/api/me` to retrieve the user's roles and profile from the
   agent service. The home app still reads Firestore directly for its own auth flow.

### Role-based access control

User access is controlled via four stackable roles stored in Firestore `users/{email}` documents.
Roles are global (not per-app) and a user can hold multiple roles.

#### Roles

| Role | Regular apps | Vendor spend | Admin capabilities | Assigned by |
|------|-------------|-------------|-------------------|-------------|
| `user` | stocks, vendors | Only `allowed_vendor_ids` | None | `admin` via System Admin UI |
| `admin` | stocks, vendors | Only `allowed_vendor_ids` | Create users, grant `user`/`admin` roles | `admin` via System Admin UI |
| `finance_admin` | None (needs `user`/`admin` too) | All spend (bypasses filtering) | Grant `allowed_vendor_ids` to users | Manual Firestore |
| `haderach_user` | card | N/A | None | Manual Firestore |

#### Admin apps

| App | Route | Required role |
|-----|-------|--------------|
| System Administration | `/admin/system/` | `admin` |
| Finance Administration | `/admin/finance/` | `finance_admin` |

Admin app access is defined in `ADMIN_CATALOG` and `ADMIN_GRANTING_ROLES` in
`@haderach/shared-ui` (`haderach-home/packages/shared-ui/src/auth/app-catalog.ts`).

#### Permission resolution

Each app defines an `APP_GRANTING_ROLES` mapping in code. Admin apps use a separate
`ADMIN_GRANTING_ROLES` mapping. Access is granted if the user holds any role that
grants access to that app. Role-to-permission mapping is intentionally in code
(not Firestore) — the role set is small and well-defined.

#### Firestore schema

```text
users/{normalizedEmail}
  roles: string[]              // e.g., ["admin", "finance_admin"]
  allowed_vendor_ids: string[] // vendor doc IDs for spend filtering
  first_name: string
  last_name: string
  createdAt: string            // ISO timestamp
```

### Managing users

Users with the `admin` role can manage users via the System Administration app
at `/admin/system/`. This app supports creating users, assigning `user`/`admin`
roles, and deleting users.

`finance_admin` and `haderach_user` roles are assigned manually in the
[Firebase Console](https://console.firebase.google.com) under the `haderach-ai`
project → Firestore Database → `users` collection.

Initial data is seeded using `scripts/seed-users.py`.

### Fail-closed behavior

If the user doc fetch fails (agent API unreachable, network error, or missing
document), apps return an empty roles array — the user is denied access until the
service is reachable. The home app falls back similarly on direct Firestore read
failure.

### Security rules

Defined in `firestore.rules` and deployed via `firebase deploy`:

- `users/{email}`: read allowed if authenticated; writes denied from client SDKs.
- `vendors/{vendorId}`: read allowed if authenticated; writes denied from client SDKs. Writes are performed via Admin SDK (seed script, agent service).
- `allowlists/{appId}`: retained for backward compatibility during migration.
- Admin writes go through the Firebase Console or Admin SDK scripts.

### Infrastructure

- Firestore Native mode is provisioned via `infra/firestore.tf`.
- User data is seeded using `scripts/seed-users.py`.

### Forward compatibility

`APP_CATALOG`, `APP_GRANTING_ROLES`, and auth primitives (`BaseAuthUser`,
`fetchUserDoc`, `buildDisplayName`) are centralized in `@haderach/shared-ui`
(`haderach-home/packages/shared-ui/src/auth/`). All app repos import from this
single source of truth. When onboarding a new app, update the catalog and role
mapping there — no per-app copies to maintain.

### Legacy: allowlists collection

The `allowlists` collection and its Firestore rules remain in place for rollback
safety. It can be removed once all apps are confirmed stable on the RBAC model.

## Security and Indexing Defaults

Default indexing policy is deny-by-default:

- Platform sets `X-Robots-Tag: noindex, nofollow, noarchive`.
- Individual app routes can be explicitly allowlisted by platform review.
- No public indexing by default until explicit approval.
