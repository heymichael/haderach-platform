# Demo Data Policy

**Owner:** Michael Mader (michael@haderach.ai)  
**Status:** Draft — interim control pending dedicated demo environment  
**Last reviewed:** 2026-04-22  
**Review cadence:** Quarterly (or on process change)

---

## Purpose

Defines how production-derived data may be used for demos and local development
without expanding unnecessary access to confidential information.

This is an interim control while Haderach continues to use production code for
demos and has not yet stood up a separate long-lived demo environment.

---

## Scope

Applies to:

- Production database exports, snapshots, and filtered extracts
- Curated demo datasets derived from production data
- Local development databases seeded from curated demo data
- Any human access path used to prepare or refresh demo data

This policy does not change production runtime access required by deployed
services. It governs human access and developer workflows.

---

## Policy

1. Production-derived demo data may only be pulled by the policy owner unless
   another person is explicitly approved in writing.
2. Other developers must not pull raw production database snapshots or direct
   production extracts for local use.
3. Shared demo or seed data must come from a curated dataset prepared from
   production data, not from an ad hoc raw snapshot.
4. The curated demo dataset is also the default shared dataset for local
   development unless a task explicitly requires a different dataset.
5. Curated demo data must be limited to the minimum records and fields needed
   for demos, testing, and local development.
6. Secrets, tokens, credentials, and other non-demo operational data must not
   be included in the curated dataset.
7. Production-derived raw exports are temporary working artifacts and must not
   become the team-wide default local dataset.
8. The preferred shared development path is a local database seeded from the
   curated demo dataset.

---

## Required Controls

- **Least privilege:** Human access to production database contents is limited
  to the minimum number of people required to prepare curated demo data.
- **Single export path:** One controlled production-to-demo data preparation
  path is maintained, rather than allowing each developer to generate their own
  local snapshot from production.
- **Curation before sharing:** Data is reviewed and reduced before it is shared
  with other developers.
- **Local-only use:** Curated demo data is intended for demo and development
  use in non-production environments.
- **Refresh discipline:** When the curated dataset is refreshed, the prior
  version should be replaced or retired rather than left to accumulate without
  ownership.

---

## Minimum Operational Record

Each production-derived demo data refresh should record:

- date
- who pulled the source data
- purpose
- where the curated dataset was stored
- what was intentionally excluded or reduced

This record may live in a lightweight runbook, changelog, or task record.

---

## Exceptions

Any exception to this policy must be approved by the owner and documented with:

- who is receiving access
- why the exception is needed
- how long the exception lasts
- what data is in scope

---

## Related Documents

- `docs/demo-data-runbook.md`
- `docs/incident-response-policy.md`
- `docs/vendor-risk-register.md`
