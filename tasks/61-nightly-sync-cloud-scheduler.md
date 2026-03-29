---
id: "61"
title: "Set up Cloud Scheduler for nightly vendor and spend sync jobs"
status: pending
group: platform
phase: platform
priority: high
type: feature
tags: [cloud-scheduler, cloud-run-job, terraform, sync, vendors, spend, infra, vendor-data]
dependencies: ["56"]
effort: medium
created: 2026-03-25
---

# Set up Cloud Scheduler for nightly vendor and spend sync jobs

## Purpose

The sync scripts (`sync_billcom.py` for vendor metadata, `sync_billcom_spend.py` for Bill.com spend aggregation, `sync_aws_spend.py` for AWS Cost Explorer spend) are currently run manually. They need to run nightly on a schedule to keep Firestore data current.

## What needs to happen

### 1. Cloud Run Jobs

Create three Cloud Run Jobs that use the agent service Docker image with different entrypoints:

- **vendor-sync**: `python -m service.sync_billcom` (~110s runtime)
- **vendor-spend-sync**: `python -m service.sync_billcom_spend` (~200–270s runtime)
- **aws-spend-sync**: `python -m service.sync_aws_spend` (~10s runtime)

All need:
- Same image as agent-api: `us-central1-docker.pkg.dev/haderach-ai/haderach-apps/agent-api`
- Firestore access via default compute service account
- Timeout: 600s (generous buffer)
- Max retries: 1

Secrets:
- vendor-sync and vendor-spend-sync: `VENDOR_BILL_CREDENTIALS` from Secret Manager
- aws-spend-sync: `VENDOR_AWS_BILLING_CREDENTIALS` from Secret Manager

### 2. Cloud Scheduler

Three scheduler jobs:

- **vendor-sync-nightly**: triggers vendor-sync Cloud Run Job (e.g. `0 2 * * *` PT)
- **vendor-spend-sync-nightly**: triggers vendor-spend-sync Cloud Run Job (e.g. `0 3 * * *` PT, after vendor sync completes)
- **aws-spend-sync-nightly**: triggers aws-spend-sync Cloud Run Job (e.g. `0 3 * * *` PT, can run in parallel with Bill.com spend sync)

Bill.com spend sync should run after vendor sync so that denormalized vendor metadata in spend docs is fresh. AWS spend sync has no dependency on vendor sync.

### 3. Terraform

All resources defined in `haderach-platform/infra/`:
- `google_cloud_run_v2_job` for each sync job (3 jobs)
- `google_cloud_scheduler_job` for each trigger (3 jobs)
- Service account with Cloud Run Invoker role for Scheduler
- IAM bindings for secret access

### 4. Enum drift detection and PR creation

After the sync jobs run, a follow-up step should detect whether the hardcoded enum values in the MCP analytics server (`agent/mcp_server/resolver.py` → `ENUM_FIELDS`) have drifted from the actual distinct values in Firestore.

**Fields to check:** `paymentMethod`, `accountType`, `track1099`, `billingFrequency`, `toolCall`, `hide` (the enum fields in `ENUM_FIELDS`).

**Process:**
1. Query Firestore for distinct values of each enum field across the `vendors` collection.
2. Compare to the hardcoded lists in `resolver.py`.
3. If identical → log "enums in sync", done.
4. If different → create a feature branch, patch `resolver.py` (and `prompts.py` if the prompt references those values), open a PR with a clear diff showing what changed and which field drifted.

**Why a PR, not auto-deploy:** These values feed into the OpenAI tool schema and system prompt — they guide what the LLM suggests to users. A typo or bad value in the DB shouldn't silently propagate to production. The PR gives a human a chance to decide: merge the new value, or fix the data instead.

**Implementation:** This can be a standalone script (e.g. `agent/service/check_enum_drift.py`) invoked as a fourth Cloud Run Job on the same schedule, running after the sync jobs complete. It needs `gh` CLI access (or GitHub API token) to create branches and PRs. See task 68 for the MCP server context.

## Notes

- The sync scripts currently live in the agent repo (`agent/service/`). Task 58 tracks whether they should move. For now, the Cloud Run Jobs can use the agent-api image directly.
- Both scripts are idempotent — safe to re-run or retry on failure.
- Consider adding alerting on job failure (Cloud Monitoring or a simple Slack webhook).
