# Credential Lifecycle Log

Append-only record of credential creation and rotation events. Do not edit past entries.

This log is the single source of truth for all managed credentials — when they were created, by whom, and every subsequent rotation. GCP Admin Activity logs corroborate SA key events; Secret Manager version history corroborates secret events.

**Rotation cadence:** Quarterly for access credentials (SA keys, database passwords, API tokens). Annual or on-compromise for signing/infrastructure keys (see `access-review-policy.md` for classification).

---

## Log format

Each entry includes:
- **Event** — `created` or `rotated`
- **Service/SA** — what credential this is
- **Credential location** — where it lives (Secret Manager, file on disk, etc.)
- **Created by** — identity that performed the action
- For rotations: **Key deleted** and **Key created** with IDs
- **Post-state** — confirmation of current state after the event

---

## Entries

> **Note:** Credentials created before 2026-04-14 predate this log convention. Their original creation is documented in Terraform history and GCP audit logs. The entries below begin at first rotation or, for newer credentials, at creation.

### 2026-04-14 — agent-local-dev

- **SA:** `agent-local-dev@haderach-ai.iam.gserviceaccount.com`
- **Key deleted:** `0a0523eca4f50079b9acec6b276419f569b4484a` (created 2026-03-29)
- **Key created:** `0cd8a20ba9dad1a037dfee4704a1f32ef79871b3` (created 2026-04-14)
- **Rotated by:** michael@haderach.ai
- **Post-rotation state:**
  ```
  KEY_ID                                    CREATED_AT            EXPIRES_AT            DISABLED
  d6177534964ad6049eed602aaa1bab2b1f04202f  2026-04-01T12:24:41Z  2026-04-18T12:24:41Z
  2232bddfaaa7ba3749492fd6e4a68fb8f232e4f8  2026-04-10T12:24:41Z  2026-04-26T12:24:41Z
  0cd8a20ba9dad1a037dfee4704a1f32ef79871b3  2026-04-14T19:41:33Z  9999-12-31T23:59:59Z
  ```
  _(two short-lived keys are Google-managed system keys; `0cd8...` is the user-managed key on disk)_

---

### 2026-04-14 — OpenAI API key

- **Service:** OpenAI API (platform.openai.com)
- **Key revoked:** `sk-...ader` (name unknown — rotated out)
- **Key created:** `haderach-platform-agent` (`sk-...fjkA`)
- **Rotated by:** michael@haderach.ai
- **Credential location:** `agent/openai-api-key.txt` (gitignored, chmod 600)
- **Post-rotation state:** Old key revoked in OpenAI dashboard; new key active and confirmed loaded by agent service

---

### 2026-04-14 — Postgres database password (haderach-app)

- **Service:** Cloud SQL — instance `haderach-main`, project `haderach-ai`
- **User rotated:** `haderach-app`
- **Rotated by:** michael@haderach.ai
- **Method:** `gcloud sql users set-password haderach-app --instance=haderach-main --project=haderach-ai --prompt-for-password`
- **Credential location:** `agent/haderach-database-url.txt` (gitignored); production via Secret Manager
- **Post-rotation state:** New password set in Cloud SQL; `haderach-database-url.txt` updated; agent connectivity confirmed (`session_user: haderach-app`)

---

### 2026-04-14 — Postgres database password (cms-app) — CREATED

- **Event:** created
- **Service:** Cloud SQL — instance `haderach-cms`, project `haderach-ai`
- **User:** `cms-app`
- **Created by:** Terraform (`random_password.cms_db_password`, applied by michael@haderach.ai)
- **Credential location:** Secret Manager (`CMS_DATABASE_URL`, version 1); local dev via `haderach-cms/cms-database-url.txt` (gitignored)
- **Classification:** access credential (quarterly rotation)
- **Method:** Auto-generated 32-char random password via Terraform; connection string auto-populated in Secret Manager
- **Terraform PR:** heymichael/haderach-platform#47

---

### 2026-04-14 — PAYLOAD_SECRET — CREATED

- **Event:** created
- **Service:** Payload CMS JWT signing key
- **Created by:** michael@haderach.ai (via `openssl rand -base64 32 | gcloud secrets versions add`)
- **Credential location:** Secret Manager (`PAYLOAD_SECRET`, version 1); local dev uses throwaway value in `.env`
- **Classification:** signing/infrastructure key (annual or on-compromise rotation)
- **Method:** `openssl rand -base64 32 | gcloud secrets versions add PAYLOAD_SECRET --data-file=-`
- **Terraform PR:** heymichael/haderach-platform#47 (secret container); value seeded manually

---

### 2026-04-14 — CMS_API_KEY — CREATED (empty)

- **Event:** created (container only — no value yet)
- **Service:** Server-to-server API key for agent → Payload CMS
- **Created by:** Terraform (applied by michael@haderach.ai)
- **Credential location:** Secret Manager (`CMS_API_KEY`, no version yet)
- **Classification:** access credential (quarterly rotation)
- **Method:** Secret container created by Terraform; value to be set after first Payload deploy (create agent user in admin UI, copy API key)
- **Terraform PR:** heymichael/haderach-platform#47

---

### 2026-04-14 — cms-api-runner SA — CREATED

- **Event:** created
- **Service:** Cloud Run runtime identity for `cms-api`
- **SA:** `cms-api-runner@haderach-ai.iam.gserviceaccount.com`
- **Created by:** Terraform (applied by michael@haderach.ai)
- **Credential location:** No JSON key — Cloud Run uses SA directly via IAM
- **Classification:** N/A (no key to rotate; SA identity managed by GCP)
- **Terraform PR:** heymichael/haderach-platform#47

---

### 2026-04-14 — cms-artifact-publisher SA — CREATED

- **Event:** created
- **Service:** CI/CD image push for `haderach-cms` repo
- **SA:** `cms-artifact-publisher@haderach-ai.iam.gserviceaccount.com`
- **Created by:** Terraform (applied by michael@haderach.ai)
- **Credential location:** No JSON key — WIF to be configured when CI/CD is set up
- **Classification:** N/A (WIF keyless; no key to rotate)
- **Terraform PR:** heymichael/haderach-platform#47
