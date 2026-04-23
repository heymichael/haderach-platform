# Service Account Matrix

Canonical record of all Haderach platform service accounts. Updated whenever a SA is created, modified, or deleted. Reviewed quarterly alongside key rotation.

**Owner:** Michael Mader (michael@haderach.ai)  
**Last reviewed:** 2026-04-23

---

## Matrix

### Frontend artifact publishers (GCS-based deploy)

These SAs are used by GitHub Actions in each frontend repo to publish immutable build artifacts to GCS. The platform deployer then reads those artifacts to reconstruct the hosted state.

| SA Name | Email | Purpose | Scope | Roles | Credential location | Rotation cadence | Notes |
|---|---|---|---|---|---|---|---|
| stocks-artifact-publisher | stocks-artifact-publisher@haderach-ai.iam.gserviceaccount.com | CI/CD artifact publish for heymichael/stocks repo | Bucket: haderach-app-artifacts | `roles/storage.objectAdmin` | WIF (keyless via GitHub Actions) | N/A — keyless | ⚠️ Bucket-wide objectAdmin — can read/write all apps' artifacts. Should be prefix-conditioned to `stocks/`. See open findings. |
| expenses-artifact-publisher | expenses-artifact-publisher@haderach-ai.iam.gserviceaccount.com | CI/CD artifact publish for heymichael/expenses repo | Bucket: haderach-app-artifacts | `roles/storage.objectAdmin` | WIF (keyless via GitHub Actions) | N/A — keyless | ⚠️ Same bucket-wide objectAdmin issue. |
| vendors-artifact-publisher | vendors-artifact-publisher@haderach-ai.iam.gserviceaccount.com | CI/CD artifact publish for heymichael/vendors repo | Bucket: haderach-app-artifacts | `roles/storage.objectAdmin` | WIF (keyless via GitHub Actions) | N/A — keyless | ⚠️ Same bucket-wide objectAdmin issue. |
| home-artifact-publisher | home-artifact-publisher@haderach-ai.iam.gserviceaccount.com | CI/CD artifact publish for heymichael/haderach-home repo | Bucket: haderach-app-artifacts | `roles/storage.objectAdmin` | WIF (keyless via GitHub Actions) | N/A — keyless | ⚠️ Same bucket-wide objectAdmin issue. |
| admin-sys-artifact-publisher | admin-sys-artifact-publisher@haderach-ai.iam.gserviceaccount.com | CI/CD artifact publish for heymichael/system-admin repo | Bucket: haderach-app-artifacts | `roles/storage.objectAdmin` | WIF (keyless via GitHub Actions) | N/A — keyless | ⚠️ Same bucket-wide objectAdmin issue. |
| admin-vend-artifact-publisher | admin-vend-artifact-publisher@haderach-ai.iam.gserviceaccount.com | CI/CD artifact publish for heymichael/admin-vendors repo | Bucket: haderach-app-artifacts | `roles/storage.objectAdmin` | WIF (keyless via GitHub Actions) | N/A — keyless | ⚠️ Same bucket-wide objectAdmin issue. |

### Backend service publishers (Artifact Registry + Cloud Run)

These SAs are used by GitHub Actions to build and push Docker images to Artifact Registry, then deploy new Cloud Run revisions.

| SA Name | Email | Purpose | Scope | Roles | Credential location | Rotation cadence | Notes |
|---|---|---|---|---|---|---|---|
| agent-artifact-publisher | agent-artifact-publisher@haderach-ai.iam.gserviceaccount.com | CI/CD — build/push agent-api image and deploy to Cloud Run | AR: haderach-apps repo; Project: haderach-ai | `roles/artifactregistry.writer` (AR-scoped), `roles/run.developer` (project), `roles/iam.serviceAccountUser` on agent-api-runtime AND on default compute SA, `roles/cloudsql.client` (project), `roles/secretmanager.secretAccessor` on DATABASE_URL | WIF (keyless via GitHub Actions) | N/A — keyless | `cloudsql.client` and `DATABASE_URL` access are for SchemaSpy doc generation in CI — unusual role for a publisher SA. `run.developer` is project-wide (no narrower scope available for Cloud Run deploys). Now acts-as `agent-api-runtime` (added task #271, 2026-04-21). The legacy `iam.serviceAccountUser` on default compute SA is now redundant for agent-api deploys but retained until a follow-up cleanup confirms no other workflow depends on it. |
| cms-artifact-publisher | cms-artifact-publisher@haderach-ai.iam.gserviceaccount.com | CI/CD — build/push cms-api image, run migrations, deploy to Cloud Run | AR: haderach-apps repo; Project: haderach-ai; Secret: CMS_DATABASE_URL | `roles/artifactregistry.writer` (AR-scoped), `roles/run.developer` (project), `roles/iam.serviceAccountUser` on cms-api-runner, `roles/cloudsql.client` (project), `roles/secretmanager.secretAccessor` on CMS_DATABASE_URL | WIF (keyless via GitHub Actions) | N/A — keyless | Created task #227, approved 2026-04-15. Acts-as `cms-api-runner` specifically. `cloudsql.client` and CMS_DATABASE_URL access added task #240 (approved 2026-04-18) for SOC 2 compliant CI migrations via Cloud SQL Proxy. |
| site-artifact-publisher | site-artifact-publisher@haderach-ai.iam.gserviceaccount.com | CI/CD — build frontend artifact, upload to GCS | Bucket: haderach-app-artifacts | `roles/storage.objectAdmin` (bucket-scoped) | WIF (keyless via GitHub Actions) | N/A — keyless | Created task #240. Originally set up for Cloud Run deploy, switched to GCS artifact pattern for consistency with other frontend apps (2026-04-18). |

### Cloud Run runtime identities

These SAs are attached as the identity of Cloud Run services at runtime. They access secrets and databases on behalf of the running service.

| SA Name | Email | Purpose | Scope | Roles | Credential location | Rotation cadence | Notes |
|---|---|---|---|---|---|---|---|
| _(default compute SA)_ | {project_number}-compute@developer.gserviceaccount.com | Runtime identity for vendors-api, stocks-api (not Terraform-managed). agent-api migrated off this SA per task #271 (2026-04-21). | Project: haderach-ai | `roles/cloudsql.client` (project), `roles/secretmanager.secretAccessor` on: DATABASE_URL, VENDOR_AWS_BILLING_CREDENTIALS, MASSIVE_API_KEY | WIF (keyless via Cloud Run) | N/A — keyless | ⚠️ vendors-api and stocks-api still share this SA. Each can access all secrets granted to it. Least-privilege fix: give each remaining service a dedicated runtime SA like `cms-api-runner` and `agent-api-runtime`. Tracked as open finding (#2). |
| cms-api-runner | cms-api-runner@haderach-ai.iam.gserviceaccount.com | Cloud Run runtime identity for cms-api (Payload CMS) | Instance: haderach-cms Cloud SQL | `roles/cloudsql.client` (project-level, could be instance-scoped), `roles/secretmanager.secretAccessor` on CMS_DATABASE_URL, PAYLOAD_SECRET, CMS_API_KEY | WIF (keyless via Cloud Run) | N/A — keyless | Created task #227, approved 2026-04-14. `cloudsql.client` is project-level; narrower instance-level binding not easily expressed in Terraform IAM members — acceptable risk given single-tenant setup. |
| agent-api-runtime | agent-api-runtime@haderach-ai.iam.gserviceaccount.com | Cloud Run runtime identity for agent-api | Project: haderach-ai | `roles/cloudsql.client` (project), `roles/secretmanager.secretAccessor` on DATABASE_URL, OPENAI_API_KEY, CMS_API_KEY | WIF (keyless via Cloud Run) | N/A — keyless | Originally created out-of-band; brought under Terraform via task #271 (2026-04-21). CMS_API_KEY binding added under bug #269 (2026-04-21). Vendor billing secret bindings (AWS/Bill/GCP) intentionally not granted yet — agent-api does not consume those env vars in production today (no scheduler). They will be added when nightly vendor sync moves to a dedicated Cloud Run job. |

### Platform and infra SAs

| SA Name | Email | Purpose | Scope | Roles | Credential location | Rotation cadence | Notes |
|---|---|---|---|---|---|---|---|
| haderach-platform-deployer | haderach-platform-deployer@haderach-ai.iam.gserviceaccount.com | Firebase Hosting deploys; reads app artifacts from GCS | Bucket: haderach-app-artifacts; Project: haderach-ai | `roles/firebasehosting.admin` (project), `roles/storage.objectViewer` (bucket), `roles/storage.objectAdmin` (bucket) | WIF (keyless via GitHub Actions) | N/A — keyless | objectAdmin + objectViewer is redundant (objectAdmin includes read). objectAdmin is bucket-wide — needed for writing latest-deployed.json markers. Acceptable given platform-deployer is the orchestrator role, not an app CI SA. |
| strategy-docs-uploader | strategy-docs-uploader@haderach-ai.iam.gserviceaccount.com | Upload gitignored strategy documents to GCS when explicitly requested by the operator | Bucket: haderach-strategy-documents | `roles/storage.objectUser` (bucket-scoped) | JSON key at `~/.config/haderach/strategy-docs-uploader-sa.json` | Quarterly | Created task #276, approved 2026-04-22. Used for manual strategy document sync only — unlike raw transcripts, documents are not uploaded automatically on creation/edit. |
| mixpanel-bigquery-reader | mixpanel-bigquery-reader@haderach-ai.iam.gserviceaccount.com | Reads Mixpanel BigQuery export data | Project: haderach-ai | `roles/bigquery.dataViewer` (project-level), `roles/bigquery.jobUser` (project-level) | JSON key stored as `MIXPANEL_BIGQUERY_SERVICE_ACCOUNT_API` secret in Secret Manager | Quarterly | ⚠️ `bigquery.dataViewer` at project level grants read access to ALL BigQuery datasets in the project, not just the Mixpanel export. Should be restricted to the specific export dataset once it is pinned. |
| test-results-publisher | test-results-publisher@haderach-ai.iam.gserviceaccount.com | Publishes pytest JSON reports to GCS from CI and MCP test server | Bucket: haderach-app-artifacts, prefix: test-results/ | `roles/storage.objectAdmin` (prefix-conditioned to `test-results/`), `roles/storage.objectViewer` (bucket-wide) | WIF (keyless via GitHub Actions in heymichael/agent); JSON key at `agent/test-results-publisher-key.json` (local MCP use) | Quarterly for JSON key | objectAdmin correctly prefix-scoped. ⚠️ objectViewer is bucket-wide — grants read access to all app artifacts, not just test-results. Should add prefix condition to match objectAdmin scope. JSON key used for local MCP server only. |

### Local dev SAs

| SA Name | Email | Purpose | Scope | Roles | Credential location | Rotation cadence | Notes |
|---|---|---|---|---|---|---|---|
| agent-local-dev | agent-local-dev@haderach-ai.iam.gserviceaccount.com | Local development — agent service runtime, Postgres via Cloud SQL Proxy, Firebase token verification | Project: haderach-ai | `roles/cloudsql.client`, `roles/firebaseauth.admin` | `agent/agent-local-dev-sa-key.json` (JSON key, gitignored, chmod 600) | Quarterly | `firebaseauth.admin` is overpowered for ID token verification — no narrower built-in role exists in GCP for this use case. Accepted risk, documented. `datastore.user` removed 2026-04-14. |

### Bucket-only IAM (no service account)

These bindings grant access to GCS buckets directly to user/group identities — no SA is created or managed for the workflow.

| Bucket | Principal | Role | Purpose | Notes |
|---|---|---|---|---|
| haderach-demo-data | `user:michael@haderach.ai` | `roles/storage.objectAdmin` (bucket-scoped) | Owner-only writer for the curated demo / shared local-dev dataset | Per `docs/demo-data-policy.md`, the policy owner is the only writer. No SA is used because the owner already authenticates as themselves via `gcloud auth login`. Created task #239, approved 2026-04-22. |
| haderach-demo-data | `group:haderach-developers-data@haderach.ai` | `roles/storage.objectViewer` (bucket-scoped) | Read-only access for developers to download the curated artifact for local dev | Group membership is managed in Google Workspace, not Terraform. Add/remove members in the group to grant/revoke access. Created task #239, approved 2026-04-22. |

### Planned / in-progress SAs

| SA Name | Purpose | Status | Notes |
|---|---|---|---|
| etl-runner | ETL pipeline execution | Planned — not yet in Terraform | Credential type TBD when ETL ships. Confirm scope (Cloud SQL, GCS, etc.) at that time. |

---

## Open least-privilege findings

| # | SA(s) | Finding | Severity | Remediation |
|---|---|---|---|---|
| 1 | stocks-, expenses-, vendors-, home-, admin-sys-, admin-vend-artifact-publisher | `objectAdmin` on full `haderach-app-artifacts` bucket — any frontend CI job can overwrite any other app's artifacts | Medium | Add IAM conditions restricting each SA to its own prefix (`<app_id>/`). Same pattern already in place for `test-results-publisher`. |
| 2 | default compute SA | vendors-api, stocks-api still share the default compute SA — each can access all secrets granted to it. agent-api remediated under task #271. | Medium | Give each remaining Cloud Run service a dedicated runtime SA (like `cms-api-runner` and `agent-api-runtime`). Tracked under task #272 (full-stack IAM/TF audit). |
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
| card-artifact-publisher | 2026-04-23 | Card app retired (task #257). Deleted SA, WIF binding, and `card_publisher_admin` GCS bucket IAM grant. Approved 2026-04-23 by Michael Mader. |
