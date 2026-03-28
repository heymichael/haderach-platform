---
id: "76"
title: "Use service account key for local agent dev instead of ADC"
status: pending
group: agent
phase: agent
priority: low
type: improvement
tags: [dev-experience, auth, gcp, local-testing]
effort: small
created: 2026-03-28
---

## Purpose

The agent service uses `gcloud auth application-default login` (ADC) for local Firestore/GCP access. These credentials periodically expire, requiring manual re-authentication (`gcloud auth application-default login`) and an agent restart. This interrupts local testing.

## Approach

1. Create a dedicated GCP service account for local dev (e.g. `agent-local-dev@haderach-ai.iam.gserviceaccount.com`) with minimal permissions:
   - `roles/datastore.user` (Firestore read/write)
   - `roles/firebaseauth.admin` (Firebase ID token verification)
2. Download the JSON key file
3. Add `GOOGLE_APPLICATION_CREDENTIALS=path/to/key.json` support to the agent's `.env` and document it in `README.md`
4. Add `*-sa-key.json` or similar pattern to `.gitignore` to prevent accidental commits
5. Update the platform `local-dev-testing.mdc` rule to document this setup

## Notes

- Service account keys on disk are less secure than ADC — acceptable for local dev, not for production
- The key never expires until explicitly rotated or deleted, eliminating the periodic re-auth friction
- `GOOGLE_APPLICATION_CREDENTIALS` is a standard GCP environment variable — the Python SDK picks it up automatically with no code changes needed
