# Demo Data Runbook

**Owner:** Michael Mader (michael@haderach.ai)  
**Status:** Draft — interim process pending dedicated demo environment  
**Last reviewed:** 2026-04-22  
**Review cadence:** Quarterly (or on process change)

---

## Purpose

Operational procedure for preparing, curating, publishing, and refreshing the
shared demo dataset referenced by `docs/demo-data-policy.md`.

This runbook is intentionally lightweight. It exists to make the current
interim process explicit and auditable until a dedicated demo system exists.

---

## Intended Outcome

The team should have:

- one approved demo dataset derived from production data
- that same dataset serving as the default shared local development dataset
- one clear owner for pulling and curating it
- one repeatable local-development path that loads the curated dataset
- one lightweight record each time the dataset is refreshed

---

## Roles

| Role | Responsibility |
|---|---|
| Policy/runbook owner | Pull production-derived source data, curate the demo dataset, approve exceptions |
| Developers | Use the approved curated dataset for local development; do not pull raw production data |

---

## Process

### 1. Decide whether a refresh is needed

Refresh the curated demo dataset when one of these is true:

- the current dataset no longer supports demos
- schema changes make the dataset unusable
- local development needs realistic newer records
- a known issue in the curated dataset needs correction

If none of those are true, reuse the existing curated dataset.

### 2. Pull source data from production

The owner pulls the minimum production-derived source data needed to build or
refresh the demo dataset.

Controls:

- use the smallest practical export scope
- avoid broad raw snapshots unless necessary for curation
- keep raw exports temporary and owner-only

### 3. Curate the demo dataset

Reduce the source data into a stable demo dataset suitable for team use.

At minimum, review for:

- only the orgs, users, vendors, and records needed for demo/dev use
- removal of secrets, tokens, credentials, and non-demo operational fields
- removal or reduction of unnecessary confidential data
- consistency of relationships so the dataset still behaves like a real system

Target shape:

- one stable demo org (or equivalent narrowly scoped dataset)
- enough records to support demos and local testing
- minimal extra data outside that scope

### 4. Publish the curated dataset

Publish the curated dataset in the approved shared format for local use.

This published artifact is the canonical shared dataset for both demos and
local development unless a task explicitly requires something else.

The format may be one of:

- SQL dump of the curated demo scope
- filtered export artifact plus import script
- other repeatable load format agreed by the owner

Requirements:

- the shared artifact must be the curated version, not the raw source pull
- the loading path must be documented and repeatable
- developers should not need direct production access to use it

**Storage location:** the curated artifact is stored in the dedicated GCS
bucket `gs://haderach-demo-data` (project `haderach-ai`). The policy owner
(`michael@haderach.ai`) is the only writer. Developers in the
`haderach-developers-data@haderach.ai` Google Group have read-only access via
`roles/storage.objectViewer`. The bucket has versioning enabled so a bad
refresh can be rolled back. The artifact is never copied into a git
repository.

Owner upload example:

```bash
gcloud storage cp \
  ./demo-dataset-2026-04-22.sql.gz \
  gs://haderach-demo-data/postgres/demo-dataset-2026-04-22.sql.gz
```

Developer download example:

```bash
gcloud storage cp \
  gs://haderach-demo-data/postgres/demo-dataset-latest.sql.gz \
  ./demo-dataset-latest.sql.gz
```

### 5. Load into local development

Developers load the curated dataset into a local database and use that as the
default demo/seed path for local development.

The local workflow should eventually be simple enough to express as:

1. start the local database
2. load schema if needed
3. import the curated demo dataset
4. start the app or service

### 6. Record the refresh

For each refresh, record:

- date
- owner
- purpose
- source pulled
- curated artifact location
- notable exclusions or reductions
- old dataset retired/replaced: yes/no

This may live in a task record, release-style changelog, or a simple log
section appended to this runbook.

### 7. Retire older data

After publishing the refreshed dataset:

- replace or retire prior curated artifacts when practical
- remove temporary raw exports when no longer needed
- avoid leaving multiple stale production-derived copies without ownership

---

## Current Gaps To Close

This runbook identifies the following implementation gaps:

1. ~~Stand up the dedicated GCS bucket and access policy for the curated demo
   artifact (owner-write, developer-read).~~ Done — task #239, 2026-04-22.
   Bucket: `gs://haderach-demo-data`. Owner: `michael@haderach.ai`
   (`objectAdmin`). Developers: `haderach-developers-data@haderach.ai`
   (`objectViewer`).
2. Define the local import command or script developers should run to load
   the artifact from GCS into a local database.
3. Define the refresh log location if it will not live in this file.
4. Define the curation checklist in more detail once the first curated dataset
   is created.

---

## Temporary Decisions

- Until a dedicated demo system exists, production code may still be used for
  demos, but shared local development data should come from the curated demo
  dataset rather than ad hoc production pulls.
- Until the local import path is formalized, the owner may prepare the curated
  artifact manually as long as each refresh is recorded.

---

## Related Documents

- `docs/demo-data-policy.md`
- `docs/incident-response-policy.md`
- `docs/vendor-risk-register.md`
