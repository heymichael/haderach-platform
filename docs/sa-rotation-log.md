# SA Key Rotation Log

Append-only record of service account key rotation events. Do not edit past entries.

GCP Admin Activity logs are the authoritative source of truth. This log is a human-readable summary for audit convenience, corroborated by GCP's own records (`CreateServiceAccountKey` / `DeleteServiceAccountKey` events).

**Rotation cadence:** Quarterly for all user-managed keys.

---

## Log format

Each entry includes:
- **SA** — service account email
- **Key deleted** — key ID of the rotated-out key and its original creation date
- **Key created** — key ID of the new key
- **Rotated by** — identity that performed the rotation
- **Post-rotation state** — output of `gcloud iam service-accounts keys list` after rotation, confirming old key is gone

---

## Entries

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
