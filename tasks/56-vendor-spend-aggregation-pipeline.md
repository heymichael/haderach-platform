---
id: "56"
title: "Vendor spend platform — LLM-driven chat + aggregation"
status: in-progress
group: vendors
phase: vendors
priority: high
type: feature
tags: [spend, aggregation, llm, firestore, cloud-scheduler, sandbox, bigquery, chat-agent, billcom]
dependencies: []
effort: large
created: 2026-03-24
---

## Purpose

Build a unified vendor spend platform with two paths:

1. **Chat path** (priority): Users ask spend questions in the chat agent. The agent uses a sandboxed Python executor to call vendor billing APIs (AWS CE, Bill.com, GCP BigQuery) live. No per-vendor fetcher code — the LLM figures out each API at runtime.

2. **Chart path**: A daily aggregation job persists monthly summaries and vendor metadata to Firestore. The chart view reads from Firestore for sub-second load times.

## Cross-project note

GCP billing data is in `arcade-prod` (separate project/billing account), not `haderach-ai`. Requires cross-project BigQuery access for the agent service.

## Phases

### Phase 1 — Chat agent spend tools ✅ (AWS + Bill.com done)

- 1a. ~~Enable GCP Billing Export to BigQuery in arcade-prod~~ (deferred)
- 1b. ✅ Sandboxed Python executor (`execute_python`) tool in agent service
- 1c. ✅ Agent system prompt with spend query instructions (AWS CE + Bill.com)
- 1d. Terraform: cross-project BigQuery IAM, add AWS creds to agent-api

**What was built (branch: `feat/billcom-agent-integration` in agent repo):**

- `requests` added to `requirements.txt`
- Bill.com v3 API section added to system prompt (`prompts.py`) with login flow, bill query examples, vendor lookup, filterable fields, and response structure
- `requests` listed in `execute_python` tool description (`tools.py`)
- `VENDOR_BILL_CREDENTIALS` env var (`.env.example` updated)
- `load_dotenv(interpolate=False)` in `app.py` to handle special chars in passwords
- Dynamic date injection in system prompt: `Today's date is {date}`
- Sandbox fixes in `sandbox.py`:
  - `ThreadPoolExecutor` shutdown with `wait=False, cancel_futures=True` to prevent server hangs on timeout
  - Timeout bumped from 30s to 120s for pagination-heavy queries

**Tested and working:**

- "What bills do I have in Bill.com?" — lists bills with vendor names, amounts, due dates, statuses
- "How much did Rhonda Bender charge in January and February?" — vendor lookup → date-filtered bill query
- "What was the total amount Rhonda Bender charged in 2024?" — annual aggregation ($46,060.50)
- AWS Cost Explorer queries continue to work as before

### Phase 2 — Firestore schema

- Add `dataSource`/`apiHint`/`credentialKey` fields on vendor docs
- Add `vendor_spend` subcollection for monthly summaries

### Phase 3 — Agent routing + `max_rounds` bump ⬅️ NEXT PRIORITY

The agent currently has 5 tools: `add_vendor`, `delete_vendor`, `get_vendor`, `modify_vendor` (all Firestore-backed) plus `execute_python` (sandbox for AWS/Bill.com). The LLM sometimes wastes rounds calling `get_vendor` (Firestore) before falling back to `execute_python` (Bill.com), exhausting the 5-round tool-call limit.

**Immediate fixes:**

- Bump `max_rounds` from 5 → 10 in `app.py`
- Add routing guidance to the system prompt so the LLM knows when to use each tool:
  - `get_vendor` / `modify_vendor` / `add_vendor` / `delete_vendor` → for managing vendors in the **app's local registry** (Firestore)
  - `execute_python` → for querying **Bill.com API** (bills, vendor data, payment info, 1099 status) or **AWS Cost Explorer** (cloud spend)
- Make clear that Bill.com vendors and Firestore vendors are **separate data stores** — a vendor existing in one doesn't mean it exists in the other

**Future (after Phase 4 daily sync):** Add a `query_billcom_vendors` tool that reads from the synced `billcom_vendors` Firestore collection with filters, eliminating the need to paginate the Bill.com API for metadata queries.

### Phase 4 — Daily sync job (vendor metadata + spend aggregation)

Cloud Run Job on Cloud Scheduler that syncs vendor metadata and spend data from Bill.com into Firestore.

**4a. Vendor metadata sync (Bill.com → Firestore)**

- Paginate `GET /v3/vendors` (~926 active vendors, 100/page, ~16s total)
- Transform nested fields to top-level booleans/strings:
  - `additionalInfo.track1099` → `track1099: true`
  - `additionalInfo.taxId` → `taxId: "..."`
  - `additionalInfo.combinePayments` → `combinePayments: true`
  - `additionalInfo.companyName` → `companyName: "..."`
- Upsert into Firestore `billcom_vendors/{vendorId}`
- This enables fast Firestore queries for vendor attribute filtering (1099 status, etc.)

**4b. Spend/bill aggregation (Bill.com → Firestore)**

- Paginate `GET /v3/bills` with date filters for the current/recent months
- Aggregate by vendor + month → write to `vendor_spend` subcollection
- Same pattern for AWS CE monthly summaries

**Why this is needed:** The Bill.com API does not support server-side filtering on `additionalInfo` fields (like `track1099`). The only filterable vendor fields are: `id`, `name`, `archived`, `accountType`, `address.country`, `billCurrency`, `paymentStatus`, `createdTime`, `updatedTime`. Any query that requires scanning vendor attributes (e.g. "list all 1099 vendors") must paginate the entire vendor list (~16s for 926 vendors, within 120s sandbox timeout but slow).

### Phase 5 — Frontend

- Chart reads from Firestore `vendor_spend` via `onSnapshot`
- Vendor metadata table powered by synced `billcom_vendors` collection

### Phase 6 — Vendor onboarding validation

- Test API at vendor add time, seed data or fall back to manual

### Phase 7 — Manual spend entry

- `record_manual_spend` tool in agent

## Deploy notes

- `VENDOR_BILL_CREDENTIALS` stored in Secret Manager (version 3 is current, versions 1–2 had quoting issues)
- Secret pushed via `python-dotenv` extraction — do NOT use `grep | cut` on `.env` files with quoted values
- Terraform in `haderach-platform/infra/` manages the secret resource, Cloud Run env binding, and IAM

## Bill.com API reference

### Authentication

Session-based auth via `POST /v3/login` (JSON body):

| API field | Env var key | Notes |
|---|---|---|
| `username` | `userName` | Email address |
| `password` | `password` | May contain special chars (`&`, `!`, etc.) |
| `organizationId` | `orgId` | Starts with `008` |
| `devKey` | `devKey` | Generated in Bill.com Settings > Sync & Integrations |

Response: `{"sessionId": "...", "organizationId": "...", "userId": "...", "trusted": false}`

Session expires after 35 min of inactivity. Subsequent calls use headers: `devKey` + `sessionId`.

Env var: `VENDOR_BILL_CREDENTIALS` — JSON string with keys `userName`, `password`, `orgId`, `devKey`. No `baseUrl` needed (defaults to `https://gateway.prod.bill.com/connect`).

### Key endpoints

| Endpoint | Use case |
|---|---|
| `GET /v3/bills` | List/filter bills by vendor, date, status |
| `GET /v3/vendors` | List/filter vendors by name, archived status |
| `GET /v3/payments` | List payments (not currently used) |

### Response structure

All list endpoints return: `{"results": [...], "nextPage": "..."}`

Pagination: max 100 per page. Only include `nextPage` in params when non-null.

### Bill object fields

`id`, `vendorId`, `vendorName`, `amount`, `paidAmount`, `dueAmount`, `scheduledAmount`, `creditAmount`, `dueDate`, `paymentStatus` (PAID/UNPAID/PARTIAL), `approvalStatus`, `invoice` (object with `invoiceNumber`, `invoiceDate`), `billLineItems`, `createdTime`, `updatedTime`, `classifications`

### Vendor object fields

`id`, `name`, `accountType`, `email`, `phone`, `address`, `paymentInformation`, `additionalInfo` (object: `taxId`, `track1099`, `combinePayments`, `companyName`), `bankAccountStatus`, `balance`, `createdTime`, `updatedTime`

### Filterable fields

**Bills:** `id`, `vendorId` (eq, in), `dueDate` (gt/gte/lt/lte), `paymentStatus` (eq, ne, in), `createdTime`/`updatedTime` (gt/gte/lt/lte), `archived`, `classifications.*`

**Vendors:** `id`, `name` (eq, starts-with), `archived` (eq, ne), `accountType`, `address.country`, `billCurrency`, `paymentStatus`, `createdTime`/`updatedTime`

**NOT filterable server-side:** `track1099`, `taxId`, `combinePayments`, or any `additionalInfo` field.

### Scale

- ~926 active vendors (10 pages at 100/page)
- Full vendor pagination: ~16s (well within 120s sandbox timeout)
- Pagination param: response returns `nextPage` value, but pass it as the **`page`** query param (not `nextPage`). When using `page`, omit `filters` and `sort` — the cursor encodes them.
- Earlier testing showed inflated counts (10,100+) due to broken pagination using `nextPage` as the param name — the API silently returned the same first page repeatedly.

## Supersedes

- Task 55 (MCP server for AWS Cost Explorer)

## Acceptance criteria

- ✅ Chat agent can answer live spend questions for AWS (Cost Explorer)
- ✅ Chat agent can answer live bill questions for Bill.com (v3 API)
- ✅ No per-vendor fetcher code — all API integration is LLM-driven via sandboxed Python execution
- Chat agent can answer live spend questions for GCP (BigQuery billing export)
- Daily sync job persists vendor metadata from Bill.com to Firestore
- Daily aggregation job persists monthly spend summaries to Firestore
- Agent routes queries to Firestore (vendor metadata) vs. live API (bills/spend) appropriately
- Chart view loads from Firestore with sub-second latency
- Manual spend entry supported via chat agent
- Vendor onboarding validates API integration before marking as API-sourced
