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

## Credential classification and rotation cadence

Not all secrets rotate on the same schedule. The quarterly cadence applies to *access credentials* — secrets that authenticate an identity and can be independently reissued. *Signing/infrastructure keys* follow a longer cadence because rotation invalidates all downstream tokens and integrations simultaneously.

| Classification | Examples | Rotation cadence | Rationale |
|---|---|---|---|
| Access credential | SA JSON keys, database passwords, API tokens, OpenAI API keys | Quarterly (90 days) | Can be rotated independently; limited blast radius per credential |
| Signing/infrastructure key | PAYLOAD_SECRET (JWT signing), encryption keys | Annual or on-compromise | Rotation invalidates all sessions and API keys across all tenants; stored in Secret Manager with documented emergency rotation procedure |

**Emergency rotation procedure for signing keys:**
1. Generate new secret value: `openssl rand -base64 32`
2. Add as new version in Secret Manager: `gcloud secrets versions add <SECRET_ID> --data-file=-`
3. Restart affected Cloud Run services to pick up new version
4. All existing sessions and API keys are invalidated — users must re-authenticate and API keys must be re-generated
5. Log the rotation event in `sa-rotation-log.md`

**Decision source:** Strategy 226-r5 (multi-tenant auth isolation boundaries)

---

## Review log

| Review date | Reviewer | Findings | Actions taken |
|---|---|---|---|
| 2026-04-14 | Michael Mader | `agent-local-dev` had unused `datastore.user` binding; `test-results-publisher` confirmed correctly conditioned to `test-results/` prefix | Removed `datastore.user`; rotated `agent-local-dev` key (see `sa-rotation-log.md`) |
| _[next quarterly review]_ | | | |
