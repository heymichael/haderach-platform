# Service Account Matrix

Canonical record of all Haderach platform service accounts. Updated whenever a SA is created, modified, or deleted. Reviewed quarterly alongside key rotation.

**Owner:** Michael Mader (michael@haderach.ai)  
**Last reviewed:** 2026-04-14

---

## Matrix

| SA Name | Email | Purpose | Scope | Roles | Credential location | Rotation cadence | Notes |
|---|---|---|---|---|---|---|---|
| agent-local-dev | agent-local-dev@haderach-ai.iam.gserviceaccount.com | Local development — agent service runtime, Postgres access, Firebase token verification | Project: haderach-ai | `roles/cloudsql.client`, `roles/firebaseauth.admin` | `agent/agent-local-dev-sa-key.json` (JSON key, gitignored) | Quarterly | `firebaseauth.admin` is overpowered for token verification; no narrower built-in role exists. Accepted risk, documented. `datastore.user` removed 2026-04-14 (Firestore no longer used). |
| test-results-publisher | test-results-publisher@haderach-ai.iam.gserviceaccount.com | Publishes test result JSON to GCS from the MCP test server | Bucket: haderach-app-artifacts, prefix: test-results/ | `roles/storage.objectAdmin` (prefix-conditioned), `roles/storage.objectViewer` | `agent/test-results-publisher-key.json` (JSON key, gitignored) | Quarterly | objectAdmin scoped to test-results/ prefix via IAM condition. objectViewer for read access to results. |
| agent-api-runtime | agent-api-runtime@haderach-ai.iam.gserviceaccount.com | Cloud Run runtime identity for the agent service in production | Project: haderach-ai | `roles/cloudsql.client` | WIF (keyless via Cloud Run) | N/A — keyless | No key on disk. Identity attached to Cloud Run service. |
| agent-artifact-publisher | agent-artifact-publisher@haderach-ai.iam.gserviceaccount.com | CI/CD — publishes built artifacts and manages Cloud Run deployments | Project: haderach-ai | `roles/run.developer`, `roles/cloudsql.client` | WIF (keyless via GitHub Actions) | N/A — keyless | Used in GitHub Actions deploy workflow. |
| haderach-platform-deployer | haderach-platform-deployer@haderach-ai.iam.gserviceaccount.com | Firebase Hosting deployments | Project: haderach-ai | `roles/firebasehosting.admin`, `roles/run.viewer` | WIF (keyless via GitHub Actions) | N/A — keyless | Used in GitHub Actions for frontend deploys. |
| cms-api-runner | cms-api-runner@haderach-ai.iam.gserviceaccount.com | Cloud Run runtime identity for CMS Payload service | Instance: haderach-cms Cloud SQL | `roles/cloudsql.client` | WIF (keyless via Cloud Run) | N/A — keyless | Created task #227, approved 2026-04-14. Access scoped to haderach-cms instance only. |
| cms-artifact-publisher | cms-artifact-publisher@haderach-ai.iam.gserviceaccount.com | CI/CD image push for haderach-cms repo | Artifact Registry | `roles/artifactregistry.writer` | WIF (keyless via GitHub Actions) | N/A — keyless | Created task #227, approved 2026-04-14. |
| etl-runner | etl-runner@haderach-ai.iam.gserviceaccount.com | ETL pipeline execution | Project: haderach-ai | `roles/cloudsql.client`, `roles/logging.logWriter` | WIF or key — TBD | Quarterly if key-based | ETL infrastructure in progress. Confirm credential type when ETL ships. |

---

## Credential security tiers

| Tier | Method | Used for |
|---|---|---|
| 1 — WIF (keyless) | GitHub Actions OIDC | CI/CD workflows — no keys on disk |
| 2 — Secret Manager | Runtime secrets | Cloud Run production services |
| 3 — JSON key on disk | Local file, gitignored, chmod 600 | Local dev and agent workflows where WIF unavailable |

---

## Removed / deprecated SAs

| SA | Removed | Reason |
|---|---|---|
| _(none yet)_ | | |
