# Service Account Matrix

Canonical record of all Haderach platform service accounts. Updated whenever a SA is created, modified, or deleted. Reviewed quarterly alongside key rotation.

**Owner:** Michael Mader (michael@haderach.ai)  
**Last reviewed:** 2026-04-18

---

## Matrix

### Frontend artifact publishers (GCS-based deploy)

These SAs are used by GitHub Actions in each frontend repo to publish immutable build artifacts to GCS. The platform deployer then reads those artifacts to reconstruct the hosted state.

| SA Name | Email | Purpose | Scope | Roles | Credential location | Rotation cadence | Notes |
|---|---|---|---|---|---|---|---|
| card-artifact-publisher | card-artifact-publisher@haderach-ai.iam.gserviceaccount.com | CI/CD artifact publish for heymichael/card repo | Bucket: haderach-app-artifacts | `roles/storage.objectAdmin` | WIF (keyless via GitHub Actions) | N/A — keyless | ⚠️ objectAdmin is bucket-wide — can read/write all apps' artifacts. Should be prefix-conditioned to `card/`. See open findings. |
| stocks-artifact-publisher | stocks-artifact-publisher@haderach-ai.iam.gserviceaccount.com | CI/CD artifact publish for heymichael/stocks repo | Bucket: haderach-app-artifacts | `roles/storage.objectAdmin` | WIF (keyless via GitHub Actions) | N/A — keyless | ⚠️ Same bucket-wide objectAdmin issue as card. |
| expenses-artifact-publisher | expenses-artifact-publisher@haderach-ai.iam.gserviceaccount.com | CI/CD artifact publish for heymichael/expenses repo | Bucket: haderach-app-artifacts | `roles/storage.objectAdmin` | WIF (keyless via GitHub Actions) | N/A — keyless | ⚠️ Same bucket-wide objectAdmin issue as card. |
| vendors-artifact-publisher | vendors-artifact-publisher@haderach-ai.iam.gserviceaccount.com | CI/CD artifact publish for heymichael/vendors repo | Bucket: haderach-app-artifacts | `roles/storage.objectAdmin` | WIF (keyless via GitHub Actions) | N/A — keyless | ⚠️ Same bucket-wide objectAdmin issue as card. |
| home-artifact-publisher | home-artifact-publisher@haderach-ai.iam.gserviceaccount.com | CI/CD artifact publish for heymichael/haderach-home repo | Bucket: haderach-app-artifacts | `roles/storage.objectAdmin` | WIF (keyless via GitHub Actions) | N/A — keyless | ⚠️ Same bucket-wide objectAdmin issue as card. |
| admin-sys-artifact-publisher | admin-sys-artifact-publisher@haderach-ai.iam.gserviceaccount.com | CI/CD artifact publish for heymichael/system-admin repo | Bucket: haderach-app-artifacts | `roles/storage.objectAdmin` | WIF (keyless via GitHub Actions) | N/A — keyless | ⚠️ Same bucket-wide objectAdmin issue as card. |
| admin-vend-artifact-publisher | admin-vend-artifact-publisher@haderach-ai.iam.gserviceaccount.com | CI/CD artifact publish for heymichael/admin-vendors repo | Bucket: haderach-app-artifacts | `roles/storage.objectAdmin` | WIF (keyless via GitHub Actions) | N/A — keyless | ⚠️ Same bucket-wide objectAdmin issue as card. |

### Backend service publishers (Artifact Registry + Cloud Run)

These SAs are used by GitHub Actions to build and push Docker images to Artifact Registry, then deploy new Cloud Run revisions.

| SA Name | Email | Purpose | Scope | Roles | Credential location | Rotation cadence | Notes |
|---|---|---|---|---|---|---|---|
| agent-artifact-publisher | agent-artifact-publisher@haderach-ai.iam.gserviceaccount.com | CI/CD — build/push agent-api image and deploy to Cloud Run | AR: haderach-apps repo; Project: haderach-ai | `roles/artifactregistry.writer` (AR-scoped), `roles/run.developer` (project), `roles/iam.serviceAccountUser` on default compute SA, `roles/cloudsql.client` (project), `roles/secretmanager.secretAccessor` on DATABASE_URL | WIF (keyless via GitHub Actions) | N/A — keyless | `cloudsql.client` and `DATABASE_URL` access are for SchemaSpy doc generation in CI — unusual role for a publisher SA. `run.developer` is project-wide (no narrower scope available for Cloud Run deploys). Acts-as default compute SA rather than a dedicated runtime SA. |
| cms-artifact-publisher | cms-artifact-publisher@haderach-ai.iam.gserviceaccount.com | CI/CD — build/push cms-api image, run migrations, deploy to Cloud Run | AR: haderach-apps repo; Project: haderach-ai; Secret: CMS_DATABASE_URL | `roles/artifactregistry.writer` (AR-scoped), `roles/run.developer` (project), `roles/iam.serviceAccountUser` on cms-api-runner, `roles/cloudsql.client` (project), `roles/secretmanager.secretAccessor` on CMS_DATABASE_URL | WIF (keyless via GitHub Actions) | N/A — keyless | Created task #227, approved 2026-04-15. Acts-as `cms-api-runner` specifically. `cloudsql.client` and CMS_DATABASE_URL access added task #240 (approved 2026-04-18) for SOC 2 compliant CI migrations via Cloud SQL Proxy. |
| site-artifact-publisher | site-artifact-publisher@haderach-ai.iam.gserviceaccount.com | CI/CD — build/push site-api image and deploy to Cloud Run | AR: haderach-apps repo; Project: haderach-ai | `roles/artifactregistry.writer` (AR-scoped), `roles/run.developer` (project), `roles/iam.serviceAccountUser` on site-runner | WIF (keyless via GitHub Actions) | N/A — keyless | Created task #240, approved 2026-04-18. Follows cms-artifact-publisher pattern — acts-as dedicated runtime SA only. |

### Cloud Run runtime identities

These SAs are attached as the identity of Cloud Run services at runtime. They access secrets and databases on behalf of the running service.

| SA Name | Email | Purpose | Scope | Roles | Credential location | Rotation cadence | Notes |
|---|---|---|---|---|---|---|---|
| _(default compute SA)_ | {project_number}-compute@developer.gserviceaccount.com | Runtime identity for agent-api, vendors-api, stocks-api (not Terraform-managed) | Project: haderach-ai | `roles/cloudsql.client` (project), `roles/secretmanager.secretAccessor` on: DATABASE_URL, OPENAI_API_KEY, VENDOR_AWS_BILLING_CREDENTIALS, VENDOR_BILL_CREDENTIALS, VENDOR_GCP_BILLING_CREDENTIALS, MASSIVE_API_KEY, CMS_API_KEY | WIF (keyless via Cloud Run) | N/A — keyless | ⚠️ Three distinct services (agent-api, vendors-api, stocks-api) share this SA. Each service can access all secrets granted to this SA, including secrets for sibling services (e.g. stocks-api can technically read OPENAI_API_KEY). Least-privilege fix: give each service a dedicated runtime SA like cms-api-runner. Tracked as open finding. |
| cms-api-runner | cms-api-runner@haderach-ai.iam.gserviceaccount.com | Cloud Run runtime identity for cms-api (Payload CMS) | Instance: haderach-cms Cloud SQL | `roles/cloudsql.client` (project-level, could be instance-scoped), `roles/secretmanager.secretAccessor` on CMS_DATABASE_URL, PAYLOAD_SECRET, CMS_API_KEY | WIF (keyless via Cloud Run) | N/A — keyless | Created task #227, approved 2026-04-14. `cloudsql.client` is project-level; narrower instance-level binding not easily expressed in Terraform IAM members — acceptable risk given single-tenant setup. |
| site-runner | site-runner@haderach-ai.iam.gserviceaccount.com | Cloud Run runtime identity for site-api (nginx static frontend) | None (no secrets, no DB) | None | WIF (keyless via Cloud Run) | N/A — keyless | Created task #240, approved 2026-04-18. No secret or DB access needed — site-api is a static nginx container. Minimal blast radius by design. |

### Platform and infra SAs

| SA Name | Email | Purpose | Scope | Roles | Credential location | Rotation cadence | Notes |
|---|---|---|---|---|---|---|---|
| haderach-platform-deployer | haderach-platform-deployer@haderach-ai.iam.gserviceaccount.com | Firebase Hosting deploys; reads app artifacts from GCS | Bucket: haderach-app-artifacts; Project: haderach-ai | `roles/firebasehosting.admin` (project), `roles/storage.objectViewer` (bucket), `roles/storage.objectAdmin` (bucket) | WIF (keyless via GitHub Actions) | N/A — keyless | objectAdmin + objectViewer is redundant (objectAdmin includes read). objectAdmin is bucket-wide — needed for writing latest-deployed.json markers. Acceptable given platform-deployer is the orchestrator role, not an app CI SA. |
| mixpanel-bigquery-reader | mixpanel-bigquery-reader@haderach-ai.iam.gserviceaccount.com | Reads Mixpanel BigQuery export data | Project: haderach-ai | `roles/bigquery.dataViewer` (project-level), `roles/bigquery.jobUser` (project-level) | JSON key stored as `MIXPANEL_BIGQUERY_SERVICE_ACCOUNT_API` secret in Secret Manager | Quarterly | ⚠️ `bigquery.dataViewer` at project level grants read access to ALL BigQuery datasets in the project, not just the Mixpanel export. Should be restricted to the specific export dataset once it is pinned. |
| test-results-publisher | test-results-publisher@haderach-ai.iam.gserviceaccount.com | Publishes pytest JSON reports to GCS from CI and MCP test server | Bucket: haderach-app-artifacts, prefix: test-results/ | `roles/storage.objectAdmin` (prefix-conditioned to `test-results/`), `roles/storage.objectViewer` (bucket-wide) | WIF (keyless via GitHub Actions in heymichael/agent); JSON key at `agent/test-results-publisher-key.json` (local MCP use) | Quarterly for JSON key | objectAdmin correctly prefix-scoped. ⚠️ objectViewer is bucket-wide — grants read access to all app artifacts, not just test-results. Should add prefix condition to match objectAdmin scope. JSON key used for local MCP server only. |

### Local dev SAs

| SA Name | Email | Purpose | Scope | Roles | Credential location | Rotation cadence | Notes |
|---|---|---|---|---|---|---|---|
| agent-local-dev | agent-local-dev@haderach-ai.iam.gserviceaccount.com | Local development — agent service runtime, Postgres via Cloud SQL Proxy, Firebase token verification | Project: haderach-ai | `roles/cloudsql.client`, `roles/firebaseauth.admin` | `agent/agent-local-dev-sa-key.json` (JSON key, gitignored, chmod 600) | Quarterly | `firebaseauth.admin` is overpowered for ID token verification — no narrower built-in role exists in GCP for this use case. Accepted risk, documented. `datastore.user` removed 2026-04-14. |

### Planned / in-progress SAs

| SA Name | Purpose | Status | Notes |
|---|---|---|---|
| etl-runner | ETL pipeline execution | Planned — not yet in Terraform | Credential type TBD when ETL ships. Confirm scope (Cloud SQL, GCS, etc.) at that time. |

---

## Open least-privilege findings

| # | SA(s) | Finding | Severity | Remediation |
|---|---|---|---|---|
| 1 | card-, stocks-, expenses-, vendors-, home-, admin-sys-, admin-vend-artifact-publisher | `objectAdmin` on full `haderach-app-artifacts` bucket — any frontend CI job can overwrite any other app's artifacts | Medium | Add IAM conditions restricting each SA to its own prefix (`<app_id>/`). Same pattern already in place for `test-results-publisher`. |
| 2 | default compute SA | agent-api, vendors-api, stocks-api share the default compute SA — each can access all secrets granted to it | Medium | Give each Cloud Run service a dedicated runtime SA (like `cms-api-runner`). Bigger refactor; track as separate task. |
| 3 | mixpanel-bigquery-reader | `bigquery.dataViewer` at project level — can read any BigQuery dataset | Low | Restrict to the specific Mixpanel export dataset once it is confirmed. |
| 4 | test-results-publisher | `objectViewer` is bucket-wide — can read all app artifacts, not just `test-results/` | Low | Add prefix condition matching the `objectAdmin` scope. |
| 5 | agent-local-dev | `firebaseauth.admin` is the only available role for ID token verification | Accepted | No narrower GCP role exists. Documented and accepted. |

---

## Credential security tiers

| Tier | Method | Used for |
|---|---|---|
| 1 — WIF (keyless) | GitHub Actions OIDC | CI/CD workflows — no keys on disk |
| 2 — Secret Manager | Runtime secrets | Cloud Run production services |
| 3 — JSON key on disk | Local file, gitignored, chmod 600 | Local dev and MCP server workflows where WIF unavailable |

---

## Removed / deprecated SAs

| SA | Removed | Reason |
|---|---|---|
| _(none yet)_ | | |
