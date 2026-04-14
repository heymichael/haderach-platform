# Access Review Policy

**Owner:** Michael Mader (michael@haderach.ai)  
**Status:** Draft — to be completed prior to SOC 2 Type I audit  
**Last reviewed:** 2026-04-14  
**Review cadence:** Quarterly

---

## Scope

Covers all access to production systems, including:
- GCP IAM roles and bindings (service accounts and human accounts)
- GitHub repo access and team membership
- Third-party SaaS tools used in the platform (Vercel, Render, etc.)
- Production database credentials

---

## Review cadence

| Access type | Frequency |
|---|---|
| SA roles and keys | Quarterly (aligned with key rotation) |
| Human GCP IAM | Quarterly |
| GitHub repo access | Quarterly |
| SaaS tool access | Quarterly |

---

## Review procedure

1. **Pull current state** — list active SAs, IAM bindings, and keys via `gcloud`
2. **Compare to matrix** — reconcile against `docs/sa-matrix.md` and expected human access list
3. **Flag anomalies** — any role, binding, or key not matching expected state
4. **Remediate** — remove excess access, rotate stale keys
5. **Document** — append findings to review log (see below)

---

## Principles

- **Least privilege:** No role assigned beyond what is needed for the function
- **No long-lived keys for automated workflows:** Use Workload Identity Federation for CI/CD; reserve JSON keys for local dev only
- **Key age limit:** User-managed JSON keys must not exceed 90 days without rotation

---

## Review log

| Review date | Reviewer | Findings | Actions taken |
|---|---|---|---|
| 2026-04-14 | Michael Mader | `agent-local-dev` had unused `datastore.user` binding; `test-results-publisher` confirmed correctly conditioned to `test-results/` prefix | Removed `datastore.user`; rotated `agent-local-dev` key (see `sa-rotation-log.md`) |
| _[next quarterly review]_ | | | |
