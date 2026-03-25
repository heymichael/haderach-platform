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

### Phase 2 — Unified Firestore schema + nightly sync ✅ (PR pending)

Replaced the separate `billcom_vendors` concept with a **unified `vendors` collection**. All vendors live in one place — Bill.com vendors are synced nightly, non-Bill.com vendors (AWS, manual) coexist with `toolCall` routing.

**Schema — synced from Bill.com (nightly job writes these):**
- `id`, `name`, `billcomId` — the `009...` Bill.com vendor ID (also used as doc ID for synced vendors)
- `nameLower` — lowercase name for token-based fuzzy search
- `paymentMethod` — from `paymentInformation.payByType`
- `accountType` — Business / Individual
- `track1099` — boolean
- `toolCall` — set to `"billcom"` by sync job (other values: `"aws"`, `"gcp"`, `"manual"`)
- `lastSyncedAt` — ISO timestamp

**Schema — app-managed (human-entered, never overwritten by sync):**
- `owner`, `secondaryOwner`, `department`, `purpose`, `spendType`

**Schema — contract fields (created empty, filled in later):**
- `contractStartDate`, `contractEndDate`, `contractLengthMonths`
- `autoRenew`, `renewalRate`, `renewalNoticeDays`
- `billingFrequency`, `terminationTerms`

**NO PII stored** — no email, phone, address, taxId. Agent queries Bill.com live for those.

**Nightly sync script** (`service/sync_billcom.py`):
- Paginates Bill.com `GET /v3/vendors` (926 vendors, ~100s)
- Batch writes to Firestore with `merge=True` (only synced fields, ~12s for 926 docs)
- Total sync time: ~110s
- Run manually via `python -m service.sync_billcom`, Cloud Scheduler setup deferred

### Phase 3 — Agent routing + search_vendors tool ✅ (PR pending)

Replaced `get_vendor` (single Firestore lookup) with `search_vendors` (token-based fuzzy search, field filters, group_by aggregation). The agent now follows a Firestore-first routing pattern:

**Routing rules (in system prompt):**
1. Always call `search_vendors` first for any vendor question
2. If the answer is in the Firestore result (metadata), stop — do not call external APIs
3. If transactional data is needed (bills, spend, PII), use `execute_python` with the `billcomId` from the Firestore result
4. Cross-source joins (e.g. "group February spend by billing frequency") → tell user not supported yet

**search_vendors tool supports:**
- `query` — token-based fuzzy name match ("Michael Mader" matches "Michael D Mader")
- `filters` — exact-match on any field (`{"track1099": true}`, `{"paymentMethod": "Check"}`)
- `group_by` — aggregate counts by field (returns `{counts: {...}, total: N}`)

**Also in this phase (branch: `fix/agent-routing-and-truncation`, merged):**
- Tool-result truncation at 20K chars to prevent context bloat / Cloud Run 502s
- `max_rounds` bumped from 5 → 10
- Tool descriptions updated to clarify Firestore vs external API scope

**Tested and working:**
- "Look up Michael Mader" → `search_vendors` fuzzy match → Michael D Mader found (no Bill.com API call)
- "How many vendors by payment type?" → `search_vendors` with `group_by` → instant Firestore result
- "How many 1099 vendors?" → `search_vendors` with filter → 150 vendors (instant)
- "What did Rhonda Bender bill us in February 2026?" → `search_vendors` (get billcomId) → `execute_python` (exact bill query) → $5,231.25

### Deletion guard for synced vendors ✅ (done — see task 60)

Backend guard enforced in both `delete_vendor` tool handler and `DELETE /vendors/{id}` REST endpoint. Bill.com-synced vendors (docs with `billcomId`) return an error with a message suggesting `hide_vendor` instead. A `hide` boolean on vendor docs excludes them from `search_vendors` and `query_spend` results. See task 60 for full details.

### Phase 4 — Spend aggregation (Bill.com bills → Firestore) ✅

**What was built (branch: `feat/billcom-spend-aggregation` in agent repo):**

- `service/billcom_auth.py` — shared Bill.com login helper (extracted from sync_billcom.py)
- `service/sync_billcom_spend.py` — paginates all Bill.com bills (~1,943), aggregates by vendor + month (~1,244 buckets), denormalizes vendor metadata, batch-writes to top-level `vendor_spend` Firestore collection. Run via `python -m service.sync_billcom_spend` (~200–270s)
- `vendor_spend` doc schema: `vendorId`, `vendorName`, `month` (YYYY-MM), `totalAmount`, `billCount`, `toolCall`, `lastSyncedAt`, plus denormalized fields: `paymentMethod`, `billingFrequency`, `department`, `owner`, `track1099`, `accountType`, `purpose`, `spendType`, `hide`
- `query_spend` tool — queries `vendor_spend` directly with month filters, vendor name substring, and `group_by` aggregation (sums totalAmount/billCount/vendorCount per group). Excludes hidden vendors via live lookup.
- `search_vendors` extended with `include_spend` param — attaches per-vendor monthly spend array from Firestore
- Fuzzy vendor resolution added to system prompt (acronym/abbreviation expansion — see task 47)
- Sub-monthly granularity warning in prompt for Bill.com vendors
- Cross-source joins now supported (e.g. "group spend by billing frequency")
- AWS CE spend aggregation deferred to a future phase

**Tested and working:**

- "Total spend in February by payment type" → `query_spend` with `group_by: paymentMethod` → instant Firestore result ($817K across 4 payment methods)
- "Spend since mid-2025 by 1099 vs non-1099" → `query_spend` with date range + `group_by: track1099` → $2.1M (1099) vs $4.8M (non-1099)
- "How much did Rhonda Bender spend?" → `search_vendors` with `include_spend: true` → 6 months of spend history from Firestore
- "Top vendors Q1 2026" → `query_spend` with date range, sorted by amount
- All-time spend by account type → $18.4M across 1,244 vendor-month docs

### Phase 5 — Frontend

- Update `VendorInfo` type, table columns, and edit modal to match the new unified schema
- Table needs: name, toolCall, paymentMethod, track1099, owner, department, billingFrequency
- Modal needs: all app-managed and contract fields as editable, synced fields as read-only
- Current frontend was built for the old schema and needs redesign

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
