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
│   └── (terraform modules: cloud-sql.tf, cloud-run.tf, content-api.tf, firestore.tf, etc.)
├── scripts/
│   └── seed-users.py          # deprecated — see agent/scripts/seed_users.py
├── services/
│   └── content-api/           # authenticated static-file server (docs.haderach.ai)
│       ├── Dockerfile
│       ├── app.py
│       └── requirements.txt
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

- `app_id`: which app to deploy (`home`, `card`, `expenses`, `stocks`, `vendors`, `admin-system`, or `admin-vendors`).
- `use_latest_artifact`: boolean (default true) — resolve latest main SHA automatically.
- `commit_sha`: manual app commit SHA (used only when `use_latest_artifact` is false).
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

- `deploy_all_latest`: boolean — resolve latest main SHA for any app with an empty SHA.
- Per-app inputs: `home_sha`, `card_sha`, `expenses_sha`, `stocks_sha`, `vendors_sha`,
  `admin_system_sha`, `admin_vendors_sha` — optional commit SHAs.
- Per-app latest toggles: `home_latest`, `card_latest`, `expenses_latest`, `stocks_latest`,
  `vendors_latest`, `admin_system_latest`, `admin_vendors_latest` — boolean, use latest main artifact for that app.
- `target_env`: `staging` or `production`.

Explicit SHA always takes precedence. Per-app `_latest` toggles override `deploy_all_latest` for granular control.

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

### Content Deploy (`.github/workflows/deploy-content.yml`)

Syncs static content files from the `haderach-content` repo to a GCS bucket
(`haderach-content-docs`) via `gsutil rsync`. Content is served by the
`content-api` Cloud Run service at `docs.haderach.ai`.

#### Trigger

Manual dispatch (`workflow_dispatch`) with one input:

- `target_env`: `staging` or `production`.

#### Flow

1. Check out `heymichael/haderach-content`.
2. Authenticate to GCP via Workload Identity Federation.
3. `gsutil -m rsync -r -d content/public/ gs://<CONTENT_BUCKET>/`.

### Content API Deploy (`.github/workflows/deploy-content-api.yml`)

Builds and deploys the `content-api` Cloud Run service image.

#### Trigger

Manual dispatch (`workflow_dispatch`) with one input:

- `target_env`: `staging` or `production`.

#### Flow

1. Authenticate to GCP via WIF.
2. Build Docker image from `services/content-api/`.
3. Push to Artifact Registry (`us-central1-docker.pkg.dev/<project>/haderach-apps/content-api`).
4. Deploy to Cloud Run (`content-api` service).

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
| `GCP_PROJECT_ID` | GCP project ID (used by content-api deploy) |
| `CONTENT_BUCKET` | GCS bucket for content files (`haderach-content-docs`) |

### Managed secrets (Secret Manager)

Terraform declares secret entries in `infra/secrets.tf` and `infra/content-api.tf`.
Actual values are set manually via `gcloud secrets versions add`.

| Secret | Consumer | Purpose |
|---|---|---|
| `OPENAI_API_KEY` | agent-api | OpenAI tool-calling |
| `DATABASE_URL` | agent-api, vendors-api | Cloud SQL Postgres connection |
| `VENDOR_AWS_BILLING_CREDENTIALS` | agent-api, vendors-api | AWS billing API (JSON blob) |
| `VENDOR_GCP_BILLING_CREDENTIALS` | agent-api | GCP BigQuery billing export (JSON blob) |
| `VENDOR_BILL_CREDENTIALS` | agent-api | Bill.com API (JSON blob) |
| `MASSIVE_API_KEY` | stocks-api | Massive stock market API |
| `ANTHROPIC_API_KEY` | — | Reserved |
| `FIREBASE_SERVICE_ACCOUNT` | — | Firebase Admin SDK |
| `MIXPANEL_BIGQUERY_SERVICE_ACCOUNT_API` | — | Mixpanel BigQuery integration |
| `CONTENT_OAUTH_CLIENT_ID` | content-api | Google OAuth client ID |
| `CONTENT_OAUTH_CLIENT_SECRET` | content-api | Google OAuth client secret |
| `CONTENT_SESSION_SECRET` | content-api | Cookie signing key |

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
| `expenses` | `/expenses/` | `expenses` | Deployed |
| `stocks` | `/stocks/` | `stocks` | Deployed |
| `vendors` | `/vendors/` | `vendors` | Deployed |
| `admin-system` | `/admin/system/` | `admin-system` | Deployed |
| `admin-vendors` | `/admin/vendors/` | `admin-vendors` | Deployed |
| `site` | `/site/` | `site` | Deployed |

### Settings hub

The homepage also serves a Settings hub at `/admin/` — a role-gated navigation shell that links to admin apps. This is handled by a Firebase Hosting rewrite (`/admin{,/}` → `index.html`) and rendered within the `haderach-home` SPA. It is not a separate onboarded app; it shares the `home` artifact.

## Backend Services (Cloud Run)

| Service | Route | Repo | Purpose |
|---|---|---|---|
| `vendors-api` | `/vendors/api/**` | `vendors` | Vendor spend data (AWS billing) |
| `stocks-api` | `/stocks/api/**` | `stocks` | Stock market data (Massive API) |
| `agent-api` | `/agent/api/**` | `agent` | Shared chat agent (OpenAI tool-calling, Postgres CRUD) |
| `content-api` | `docs.haderach.ai` | `haderach-platform` (services/content-api/) | Authenticated static-file server (GCS-backed, Google OAuth) |

All backend services run on Cloud Run (us-central1). `vendors-api`, `stocks-api`,
and `agent-api` are fronted by Firebase Hosting rewrites on `haderach.ai`.
`content-api` is mapped to a custom domain (`docs.haderach.ai`) and serves
authenticated static content from GCS with Google OAuth sign-in and a Postgres
user whitelist. The default compute service account is used at runtime; each
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

User access is controlled via four stackable roles stored in the Postgres `users` and
`user_roles` tables (managed by the agent service on Cloud SQL).
Roles are global (not per-app) and a user can hold multiple roles.

#### Roles

| Role | Regular apps | Vendor spend | Admin capabilities | Assigned by |
|------|-------------|-------------|-------------------|-------------|
| `user` | expenses, vendors | Only `allowed_vendor_ids` | None | `admin` via System Admin UI |
| `admin` | expenses, vendors | Only `allowed_vendor_ids` | Create users, grant `user`/`admin` roles | `admin` via System Admin UI |
| `finance_admin` | None (needs `user`/`admin` too) | All spend (bypasses filtering) | Grant `allowed_vendor_ids` to users | `admin`/`finance_admin` via Admin UI |
| `haderach_user` | card | N/A | None | `admin` via System Admin UI |

#### Admin apps

| App | Route | Required role |
|-----|-------|--------------|
| System Administration | `/admin/system/` | `admin` |
| Vendor Administration | `/admin/vendors/` | `finance_admin` |

Admin app access is defined in `ADMIN_CATALOG` and `ADMIN_GRANTING_ROLES` in
`@haderach/shared-ui` (`haderach-home/packages/shared-ui/src/auth/app-catalog.ts`).
App definitions are also stored in the Firestore `apps` collection and can be managed at runtime via the System Administration app's Apps page.

#### Settings hub entry point

The GlobalNav avatar dropdown includes a "Settings" link pointing to `/admin/`. All authenticated users see this link; the Settings hub itself filters visible admin apps based on the user's roles.

#### Permission resolution

Each app defines an `APP_GRANTING_ROLES` mapping in code. Admin apps use a separate
`ADMIN_GRANTING_ROLES` mapping. Access is granted if the user holds any role that
grants access to that app. Role-to-permission mapping is intentionally in code
(not Firestore) — the role set is small and well-defined.

#### Database schema (Postgres)

All user, role, vendor, spend, and app data is stored in Cloud SQL Postgres
(`haderach-main` instance, `haderach` database). Full schema in
`agent/migrations/001_init.sql`. Key tables:

```text
users (id UUID, email, first_name, last_name, created_at)
  └─ user_roles (user_id → users.id, role_id → roles.id)
  └─ user_allowed_departments (user_id → users.id, department_id → departments.id)
  └─ user_allowed_vendors (user_id → users.id, vendor_id → vendors.id)
  └─ user_denied_vendors (user_id → users.id, vendor_id → vendors.id)

roles (id UUID, name)  — admin, finance_admin, user, haderach_user

apps (id UUID, slug, label, path, type, sort_order)
  └─ app_granting_roles (app_id → apps.id, role_id → roles.id)
```

Seeded via `agent/scripts/seed_users.py` and `agent/scripts/seed_apps.py`.
Editable at runtime via the System Administration app (`PATCH /agent/api/apps/{id}`,
user management endpoints).

### Managing users

Users with the `admin` role can manage users via the System Administration app
at `/admin/system/`. This app supports creating users, assigning `user`/`admin`
roles, and deleting users.

`finance_admin` and `haderach_user` roles are assigned via the
agent API (`PATCH /agent/api/users/{email}`) or the `agent/scripts/seed_users.py`
Postgres seed script.

Initial data is seeded using `agent/scripts/seed_users.py`.

### Fail-closed behavior

If the user doc fetch fails (agent API unreachable, network error, or missing
document), apps return an empty roles array — the user is denied access until the
service is reachable. The home app falls back similarly on direct Firestore read
failure.

### Infrastructure

- Cloud SQL Postgres provisioned via `infra/cloud-sql.tf`.
- Firestore Native mode provisioned via `infra/firestore.tf` (retained for
  home app direct reads during transition; the agent service no longer uses Firestore).
- User data seeded via `agent/scripts/seed_users.py` (Postgres).

### Forward compatibility

`APP_CATALOG`, `APP_GRANTING_ROLES`, and auth primitives (`BaseAuthUser`,
`fetchUserDoc`, `buildDisplayName`) are centralized in `@haderach/shared-ui`
(`haderach-home/packages/shared-ui/src/auth/`). All app repos import from this
single source of truth. When onboarding a new app, update the catalog and role
mapping there — no per-app copies to maintain.

### Legacy: allowlists collection

The Firestore `allowlists` collection has been retired. Access is now controlled
entirely by the RBAC system in Postgres (roles, user_allowed_vendors, etc.).

## CI Gating and Branch Protection

All app repositories have GitHub branch protection enabled on `main`:

- Required status check: **PR checks** (the `ci.yml` workflow) must pass before merging.
- All repos run lint + build (frontend) or compile + test (agent) as part of PR CI.
- This prevents merging PRs with build failures but does not gate post-merge publish failures (which may arise from dependency drift between PR CI and publish environments).

## Security and Indexing Defaults

Default indexing policy is deny-by-default:

- Platform sets `X-Robots-Tag: noindex, nofollow, noarchive`.
- Individual app routes can be explicitly allowlisted by platform review.
- No public indexing by default until explicit approval.
