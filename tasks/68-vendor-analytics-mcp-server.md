---
id: "68"
title: "Vendor analytics MCP server"
status: done
group: agent
phase: agent
priority: high
type: feature
tags: [mcp, analytics, firestore, vendor, spend, agent, resolution]
dependencies: []
effort: large
created: 2026-03-26
---

## Canonical plan

`/Users/michaelmader_1/.cursor/plans/vendor_analytics_mcp_server_d3a0f311.plan.md`

## Purpose

Build a Firestore-backed MCP server with intent-aligned vendor analytics tools, a multi-step resolution pipeline, and a standardized ok/ambiguous/not_found response contract. Wire it into the production vendor agent as the primary data layer, replacing the current `search_vendors`/`query_spend` tool-calling pattern.

The goal is to move query-assembly intelligence out of the LLM (where it's unreliable) and into a deterministic service layer, so the LLM's job shrinks from "construct a Firestore query" to "pick the right tool from a short menu and handle the response."

## What changes

### New: `agent/mcp_server/` module

- `server.py` — MCP protocol entry point (stdio transport) for external clients (Cursor, future agents)
- `tools.py` — six intent-aligned tool handlers: `vendor_lookup`, `vendor_count`, `spend_total`, `spend_by_vendor`, `spend_by_dimension`, `top_vendors`
- `resolver.py` — single `resolve_vendor()` function used by all tools; multi-step resolution (exact ID, exact name, Firestore aliases, normalized, token/fuzzy); `resolve_filter()` for dynamic fields (department, owner)
- `period_parser.py` — deterministic parser for period strings (YYYY-MM, YYYY-QN, YYYY, YTD, last-N-months)

### Modified

- `service/tools.py` — replace `search_vendors` and `query_spend` OpenAI tool schemas with six new tools; handlers become thin wrappers calling `mcp_server.tools`
- `service/prompts.py` — replace ~300-line routing prompt with concise instructions (tool list, response contract, execute_python fallback)
- `service/firestore_client.py` — add `aliases` to vendor doc reads
- `service/sync_billcom.py` — add `aliases` to `APP_MANAGED_FIELDS`
- `requirements.txt` — add `mcp` dependency

### Unchanged

- `service/app.py` — chat loop, auth, REST endpoints
- `service/sandbox.py` — Python executor
- Nightly sync jobs
- Write tools (add/delete/modify/hide vendor)
- `execute_python` tool

## Response contract

All tools return one of: `ok`, `ambiguous`, `not_found`, `not_authorized`, `invalid_filter`. The agent handles each status with a simple rule set — no routing logic, no query construction.

## Parameter design

- **Enum (hardcoded in tool schema):** paymentMethod, accountType, track1099, billingFrequency, toolCall, hide
- **Resolve (validated against data at query time):** vendor (full resolution pipeline), department, owner, period (deterministic parser)
- All spend tools accept optional `filters` dict (AND-combined). Multiple `group_by` not supported.

## Caller context (future-proofed for task 65)

All spend tool handlers accept an optional `caller_context` with `allowed_vendor_ids` and `is_finance_admin`. Defaults to unrestricted (`None`) for this build. Actual filtering is implemented when task 65 workstream 4 is built.

## Deliverables

1. `period_parser.py` — deterministic period string parser
2. Vendor aliases in Firestore — `aliases` array field on vendor docs, seeded for well-known vendors
3. `resolver.py` — vendor resolution pipeline + filter validation
4. `mcp_server/tools.py` — six tool handlers using resolver + period_parser + firestore_client
5. `mcp_server/server.py` — MCP stdio entry point
6. Rewire production agent — new OpenAI tool schemas, thin handler wrappers
7. Simplified system prompt
8. Updated architecture docs
