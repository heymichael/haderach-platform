# Demo Data Refresh Pipeline — Implementation Plan

**Owner:** Michael Mader (michael@haderach.ai)
**Status:** Draft — implementation not yet started
**Last reviewed:** 2026-04-23

---

## Purpose

This document is the execution-level plan for building the demo data refresh
pipeline. It complements:

- **Design of record:** strategy 201 round 4
  (`haderach-tasks/tasks/strategy/201-security/201-r4-demo-data-refresh-pipeline.md`)
- **Current policy / runbook (to be updated by this work):**
  `docs/demo-data-policy.md`, `docs/demo-data-runbook.md`
- **Upstream infra task:** `#239` (local dev DB + demo-data GCS bucket).

An agent picking this up in a fresh context should read the three documents
above plus this one before writing any code.

---

## Intended outcome

A scheduled-or-on-demand job that:

1. Rebuilds the **demo org** in prod from scratch, using:
   - Haderach CMS content (mirrored) as the CMS source
   - An allowlisted subset of **Arcade** vendors + operational data
     (sanitized) as the operational source
   - Synthetic users, memberships, RBAC, and curated app entitlements
2. Publishes refreshed dumps for both DBs to `gs://haderach-demo-data/`
   (timestamped + `latest` aliases) for developer local load.

The demo org is a **composite, derived** environment — never a clone — and
never mutated by hand. Every refresh is a full rebuild of demo-org rows.

---

## Sources of truth

| Concern | Location |
|---|---|
| Strategy / decisions | `haderach-tasks/tasks/strategy/201-security/201-r4-demo-data-refresh-pipeline.md` |
| Task | `haderach-tasks/tasks/chores/277-build-demo-data-refresh-pipeline.md` |
| This plan | `haderach-platform/docs/demo-data-refresh-implementation-plan.md` |
| Policy (to be updated) | `haderach-platform/docs/demo-data-policy.md` |
| Runbook (to be updated) | `haderach-platform/docs/demo-data-runbook.md` |
| SA matrix (to be updated if new SA added) | `haderach-platform/docs/sa-matrix.md` |

---

## Target architecture

### Components

- **Refresh script** (Python CLI) — lives in `agent/scripts/refresh_demo_data.py`.
  Reason: agent repo already owns the Postgres client (`service/pg_client.py`),
  migration runner (`scripts/run_migrations.py`), and related seed scripts
  (`seed_apps.py`, `seed_users.py`, `bootstrap_local_db.py`).
- **Migrations** — live in `agent/migrations/` alongside existing ones. Next
  free numbers are `026_*.sql` and up.
- **Vendor allowlist config** — a Python module, e.g.
  `agent/scripts/demo_config.py`, holding the fixed vendor-ID allowlist plus
  synthetic user/role/entitlement fixtures. Managed only by the policy owner.
- **Audit manifest + notifications** — a `demo_refresh_runs` table recording
  run id, start/end timestamps, row counts per table, and outcome.
- **GCS publisher** — reuses `gcloud storage cp` pattern already documented in
  the runbook. Writes to existing bucket `gs://haderach-demo-data`.

### High-level data flow

```
Arcade (prod haderach-main)        Haderach (prod CMS)
         │                                  │
         ▼                                  ▼
  [refresh job, read-only query]   [refresh job, read-only query]
         │                                  │
         ▼                                  ▼
  sanitize + regen IDs             mirror content
         │                                  │
         └───────────────┬──────────────────┘
                         ▼
           demo org in prod Postgres
         (scoped truncate-and-reload,
          single transaction per DB)
                         │
                         ▼
           pg_dump → gzip → GCS
           (timestamped + latest)
```

### Where code lives (by file)

| File | Purpose |
|---|---|
| `agent/scripts/refresh_demo_data.py` | CLI entrypoint, orchestration, safety checks, transaction control |
| `agent/scripts/demo_config.py` | Vendor allowlist, synthetic users/roles/entitlements fixtures |
| `agent/scripts/demo/refresh_cms.py` | CMS mirror step (haderach → demo) |
| `agent/scripts/demo/refresh_operational.py` | Operational step (arcade → demo): ID regen, scaling, scrub |
| `agent/scripts/demo/publish_gcs.py` | pg_dump + upload to `gs://haderach-demo-data/` |
| `agent/migrations/026_demo_is_demo_flag.sql` | `orgs.is_demo` + supporting constraints |
| `agent/migrations/027_demo_refresh_runs.sql` | audit manifest table |
| `agent/migrations/028_demo_org_bootstrap.sql` | create empty demo org + seed synthetic auth fixtures |
| `haderach-platform/docs/demo-data-policy.md` | updated to reflect pipeline model |
| `haderach-platform/docs/demo-data-runbook.md` | updated to reflect pipeline model |
| `haderach-platform/docs/sa-matrix.md` | updated only if a dedicated SA is added |

> **Note:** exact split between `refresh_demo_data.py` and a `demo/` subpackage
> is a nicety — the next agent may collapse into a flatter layout if the file
> count doesn't justify a package.

---

## Prerequisites and open decisions

### Governance approvals required before implementation

Per `iam-governance.mdc`, **no SA / IAM change may be made without explicit
owner approval**. The open question is whether to:

- **Option A (preferred for safety):** create a dedicated SA
  `demo-data-refresher@haderach-ai.iam.gserviceaccount.com` with
  - `roles/cloudsql.client` (project, matches existing runtime SAs)
  - `roles/storage.objectAdmin` on `haderach-demo-data` (bucket-scoped)
  - `secretmanager.secretAccessor` on a new `DEMO_DATA_REFRESH_DATABASE_URL`
    secret pointing at prod Postgres with credentials scoped to a dedicated
    Postgres role that can only touch demo-org rows.
  - Tier 3 JSON key on the owner's machine (not WIF — job is owner-run, not
    scheduled in GitHub Actions at launch).
- **Option B (no new cloud identity):** run as the policy owner via
  `gcloud auth login` + Cloud SQL Auth Proxy. Faster to launch; less
  defensible long-term because the owner identity is broader than the job
  needs.

**Next agent must present A vs B to the owner and get explicit approval
before creating any SA, IAM binding, or secret.** Do not write Terraform
changes first.

### Configuration decisions to capture before coding

The following must be decided (by the owner) and recorded in
`demo_config.py`:

1. **Demo org slug + label** (e.g., `demo`, "Demo Company").
2. **Vendor allowlist** — internal vendor IDs from Arcade. Target industry-
   typical names (GCP, AWS, Datadog, GitHub, Slack, Figma, etc.).
3. **Synthetic user fixtures** — emails, names, membership + role assignments
   for the demo org. Firebase accounts created manually in the Haderach
   workspace with matching emails.
4. **App entitlements for the demo org** — which apps are visible
   (per 201-r4: vendors + expenses + cms, plus any admin app roles required
   to show admin UX in demo).
5. **Non-vendor reference data to copy** — departments, categories, cost
   centers. Confirm the exact list with the owner.

Until these are decided, `demo_config.py` should hold placeholder values with
clear `# TODO(owner-confirm)` markers.

---

## Schema changes (migrations)

### `026_demo_is_demo_flag.sql`

- Add `orgs.is_demo BOOLEAN NOT NULL DEFAULT FALSE`.
- Partial unique index ensuring only one org can have `is_demo = TRUE` at a
  time:
  ```sql
  CREATE UNIQUE INDEX orgs_only_one_demo
    ON orgs ((TRUE))
    WHERE is_demo;
  ```
- The refresh script will always resolve the target by
  `SELECT id FROM orgs WHERE is_demo LIMIT 1`, never by slug — this is the
  primary safety interlock.

### `027_demo_refresh_runs.sql`

```sql
CREATE TABLE demo_refresh_runs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  finished_at TIMESTAMPTZ,
  status TEXT NOT NULL CHECK (status IN ('running','succeeded','failed')),
  actor TEXT NOT NULL,                       -- gcloud identity / SA email
  source_summary JSONB NOT NULL,             -- allowlist size, CMS project, etc.
  row_counts JSONB,                          -- {table: n, ...} on success
  error_message TEXT,
  gcs_artifacts JSONB                        -- {cms: ..., main: ...} gs:// URIs
);
```

### `028_demo_org_bootstrap.sql`

- Insert the demo org with `is_demo = TRUE`.
- Insert synthetic users, memberships, roles, app entitlements from fixtures
  (data duplicated from `demo_config.py` so it's deterministic and
  migration-owned rather than script-owned — this row-set is **not** touched
  by the refresh job).
- Guarded: `ON CONFLICT DO NOTHING` so a rerun on a bootstrapped DB is inert.

> The demo org's **auth fixture rows** (users, memberships, roles,
> entitlements) are owned by the migration. The refresh job owns only
> **content and operational data** (CMS content, vendors, spend, reference
> data). This boundary is important — it means the job can't accidentally
> break login for the demo accounts.

---

## Data classification (per 201 r4)

This is the table-level playbook the refresh step must follow. Exact table
names should be confirmed against the live schema before coding.

### Haderach CMS → demo CMS (mirror)

- **Mirror as-is** — no scaling, no scrubbing. Haderach CMS content is
  non-sensitive.
- **Version history:** preserved. CMS version history is a demo surface.
- Target rows: all content in the demo CMS org. Use CMS tenant isolation to
  scope reads and writes.

### Arcade operational → demo operational

For each table keyed by `org_id`:

| Handling | Tables / fields |
|---|---|
| **Regenerate IDs/UUIDs** | all demo-side primary keys; keep an in-run `source_id → demo_id` map and rewrite FKs before insert |
| **Preserve** | `created_at`, `updated_at`, all timestamps |
| **Scale numerically** | every numeric amount field (USD, counts, line items) by the vendor's per-run factor in `[0.5, 1.5]`; one factor per vendor, drawn fresh per run, never persisted |
| **Scrub to blank** | all free-text user-entered fields: vendor notes, memo, invoice descriptions, comments, annotations |
| **Regenerate slugs** | any slug field, to avoid collisions with source-org values |
| **Keep as harmless** | external IDs (bill.com, QBO, AWS payer IDs) |
| **Copy from Arcade** | non-vendor reference data (departments, categories, cost centers) — industry-typical, not sensitive |
| **Do not copy** | backend audit / history tables, session tables, raw sync logs |
| **Not a current problem** | attachments, cached aggregates — confirm absent in schema before coding |

### Auth rows (users, memberships, roles, entitlements)

- **Do not copy from Arcade.** These rows come from the migration/bootstrap
  only.
- The refresh job must assert the expected synthetic users exist at preflight
  and abort if missing.

---

## Safety model (implementation details)

The refresh script must enforce **all** of the following, in order:

1. **Fixed source/target mapping in code.** No CLI args naming source or
   target orgs. Sources are `arcade` and `haderach-cms` literals; target is
   resolved by `SELECT id FROM orgs WHERE is_demo`.
2. **Explicit prod flag.** Refuses to run without `--prod` (or equivalent
   env). `--dry-run` is the default.
3. **Preflight assertions** — all must pass before any write:
   - target org exists and has `is_demo = TRUE`
   - allowlist non-empty and every vendor ID resolves in Arcade
   - synthetic demo users/memberships exist
   - database connection uses the dedicated role (if Option A SA chosen)
4. **Scoped deletes only.** Every `DELETE` in the refresh path has
   `WHERE org_id = <demo_id>`. No `TRUNCATE`. No unqualified `DELETE`.
5. **Singleton advisory lock.**
   ```sql
   SELECT pg_try_advisory_lock(770000001);
   ```
   Aborts if another refresh is running.
6. **Per-DB transaction.** One transaction for CMS refresh, one for
   operational refresh. Failure rolls the whole side back; the other side
   is independent.
7. **Post-run validation.** Row counts for the demo org must be within
   reasonable bounds (e.g., vendor count == allowlist size, spend rows > 0).
   On failure, rollback and mark the run `failed`.
8. **Audit manifest.** Insert `demo_refresh_runs` with
   `status='running'` at start; update to `succeeded` / `failed` at end.
9. **Notification on failure.** Simple — either a Slack webhook or an email
   via an existing notification surface. Scope: owner only.
10. **GCS publish is post-success only.** No artifact is written if either
    transaction rolled back.

---

## Implementation stages (checkpointed)

Each stage should land as its own commit (or small PR) so the next agent can
verify against the acceptance criteria before moving on.

| # | Stage | Deliverables |
|---|---|---|
| 0 | **Prereqs & approvals** | Decide A vs B on SA; get owner approval; finalize `demo_config.py` values. No code yet. |
| 1 | **Schema: `is_demo` flag** | Migration `026_demo_is_demo_flag.sql`. Apply via the existing migrations CI path. Verify local + prod. |
| 2 | **Schema: refresh audit** | Migration `027_demo_refresh_runs.sql`. |
| 3 | **Schema: demo org bootstrap** | Migration `028_demo_org_bootstrap.sql` + fixture values in `demo_config.py`. After apply, the demo org exists in prod with demo users, memberships, roles, entitlements. |
| 4 | **Refresh CLI skeleton** | `agent/scripts/refresh_demo_data.py` with arg parsing, preflight, advisory lock, transaction wrappers, audit manifest insert/update, dry-run mode. No actual data copy yet. End-to-end dry run should print the plan. |
| 5 | **CMS mirror step** | `refresh_cms.py` — wipes demo CMS content scoped to the demo CMS org, copies Haderach CMS content including version history. Transaction-wrapped. Verified in local CMS Postgres. |
| 6 | **Operational refresh step** | `refresh_operational.py` — scoped delete, ID regeneration with in-run map, per-vendor scaling, scrubbing, slug regeneration, reference-data copy. Verified against a staging or snapshot copy of Arcade before prod. |
| 7 | **Audit manifest + notification** | Notification wiring on failure path. Success path records row counts and artifact URIs. |
| 8 | **GCS export** | `publish_gcs.py` — `pg_dump` filtered to demo-org rows (CMS) and full-schema dump (operational) gzipped, uploaded to `gs://haderach-demo-data/cms/` and `.../postgres/` with timestamped + `latest` names. |
| 9 | **Docs update** | Rewrite `demo-data-policy.md` sections 3 (curation) and `demo-data-runbook.md` sections 2–4 around the pipeline model. Retain sections 5 (local load) and 6 (record) — they still apply. |
| 10 | **End-to-end rehearsal** | Full dry run in prod; full real run in prod during a low-risk window; verify local load per runbook section 5. Record the run in `demo_refresh_runs` and update sprint/task completion. |

---

## Testing strategy

- **Unit:** per-step pure functions — scaling math, ID-map building, scrub
  rules — covered by pytest.
- **Integration (local Postgres):** run the full refresh against a local
  Postgres where both the "source" and "demo" orgs live in the same DB, with
  the demo org marked `is_demo`. Verify row counts, FK integrity, scaled
  ranges, scrubbed fields, regenerated IDs.
- **Prod dry run:** preflight and plan output only; no deletes, no inserts,
  no transaction commit.
- **Prod canary:** full refresh with an extremely small allowlist (1 vendor)
  before running with the full allowlist.

---

## Rollout plan

1. Land stages 1–3 (migrations) in prod via the CI migration workflow.
2. Verify demo org exists in prod, logins work with the synthetic accounts.
3. Land stages 4–8 (code) behind the default `--dry-run` — merging to main is
   safe because no execution happens without explicit invocation.
4. Execute dry run in prod; review plan output with the owner.
5. Execute canary run (1 vendor).
6. Execute full run; publish GCS artifacts; run a local load rehearsal.
7. Land stage 9 (docs) in the same release cut.

---

## Out of scope

- **Attachments / blob storage.** Not in the schema today. Revisit when CMS
  or vendors introduces file uploads.
- **Cached aggregates.** Not in the schema today.
- **Advanced retry / resume semantics.** A failed run is re-run from scratch.
- **GCS artifact retention policy.** All historical dumps retained for now.
- **App-boundary refactor (vendors vs expenses).** Architectural smell noted
  in 201 r4; not addressed here.
- **Automated scheduling.** Job is owner-invoked to start. A scheduler
  (Cloud Run Job / Cloud Scheduler) is a future increment once the refresh is
  proven stable.

---

## Open questions the next agent must resolve

1. **SA strategy (A vs B).** Decide and get owner approval before any IAM
   change.
2. **Final vendor allowlist.** Owner supplies.
3. **Synthetic user list and their Firebase setup.** Owner supplies; confirm
   accounts exist in the Haderach workspace.
4. **Exact demo app entitlements.** Owner confirms which admin roles should
   also be demoable.
5. **Notification channel.** Slack webhook URL, email address, or existing
   ops channel — owner decides.
6. **Table inventory.** Enumerate all tables keyed by `org_id` in the
   operational DB. Classify each against the table in "Data classification"
   above. Any table that doesn't fit one of those buckets requires an
   explicit decision.
7. **CMS org isolation.** Confirm how the CMS scopes content to an org /
   tenant so the mirror step can safely scope writes. If the CMS is not
   multi-tenant at the row level today, the mirror step must be redesigned.
8. **Reference-data copy scope.** Confirm exact tables (departments,
   categories, cost centers, ...) with the owner.

---

## Relationship to other work

- **#230 (Data isolation infrastructure)** — complementary. Both rely on
  clean org-scoped deletes. Any improvement to tenant scoping from #230 is
  usable here.
- **#239 (Local dev DB)** — foundational. Provides the GCS bucket, IAM, and
  local load path this pipeline publishes into.
- **#276 (Strategy docs GCS workflow)** — unrelated mechanically but a useful
  pattern reference for dedicated-SA GCS uploads.

---

## Related documents

- `docs/demo-data-policy.md`
- `docs/demo-data-runbook.md`
- `docs/sa-matrix.md`
- `../haderach-tasks/tasks/strategy/201-security/201-r4-demo-data-refresh-pipeline.md`
- `../haderach-tasks/tasks/chores/277-build-demo-data-refresh-pipeline.md`
