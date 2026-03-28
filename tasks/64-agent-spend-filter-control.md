---
id: "64"
title: "Agent-driven spend filter control"
status: pending
group: vendors
phase: vendors
priority: medium
type: feature
tags: [vendors, chat, agent, spending, filter, context-awareness, mcp, agent-strategy]
dependencies: ["68"]
effort: medium
created: 2026-03-25
---

Full implementation plan: `/Users/michaelmader_1/haderach_org/haderach_site/haderach-platform/.cursor/plans/agent_spend_filter_control_14914001.plan.md`

## Context

The Spending chart's vendor filter is only controllable via the sidebar dropdown. Users should be able to describe what vendors they want included or excluded via the agent pane — e.g. "remove Michael Mader", "show Interexy", "just show me 1099 vendors". The agent also needs tab context awareness so that "add X" is interpreted correctly on the Spending tab (add to chart filter) vs the Vendors tab (create a new vendor).

## What changed since the original plan

Task 68 (Vendor Analytics MCP Server) delivered the resolution and validation infrastructure that the original plan was trying to build from scratch:

- **`mcp_server/resolver.resolve_vendor()`** — resolves names, aliases, IDs, partial matches to canonical vendor IDs. Returns `ok`, `ambiguous`, or `not_found`.
- **`mcp_server/resolver.validate_filters()`** — validates filter dicts against enum and dynamic field values. Returns `None` (valid) or `invalid_filter`.
- **Response contract** — the LLM already knows how to handle `ok`, `ambiguous`, `not_found`, and `invalid_filter` statuses via the system prompt.

This means the `resolve_vendor_ids()` function from the original plan is no longer needed. The new tool handler calls existing functions directly.

## Approach

Add an `update_spend_filter` tool that:
1. Accepts `action` (set/add/remove), optional `vendor_names` list, optional `filters` dict
2. Resolves vendor names via `resolve_vendor()` (existing)
3. Validates and queries by filters via `validate_filters()` + Firestore query (existing pattern)
4. Returns resolved vendor IDs back to the frontend as a `spend_filter` field on `ChatResponse`

Inject the user's current tab context (`view`, `selectedVendorCount`) into the system prompt so the agent disambiguates intent.

## Work breakdown

### Agent side (4 files)

- **`agent/mcp_server/tools.py`**: Add `handle_update_spend_filter()`. Loops `vendor_names` through `resolve_vendor()`, queries Firestore by `filters` for matching IDs, returns combined set. Follows the exact same pattern as the existing six handlers.
- **`agent/service/tools.py`**: Add `update_spend_filter` tool schema and thin handler wrapper to `TOOL_DEFINITIONS` and `TOOL_HANDLERS`.
- **`agent/service/app.py`**: Add `SpendFilterUpdate` model (action + vendor_ids). Extend `ChatResponse` with optional `spend_filter` field. Detect `update_spend_filter` results in the tool-call loop. Inject `req.context` (view, selectedVendorCount) into system prompt.
- **`agent/service/prompts.py`**: Add `update_spend_filter` to tool table. Add "UI context awareness" section explaining how to interpret add/remove/show commands differently based on which tab the user is on.

### Frontend side (2 files)

- **`vendors/src/ChatPanel.tsx`**: Accept new props (`view`, `selectedVendorCount`, `onSpendFilterUpdate`). Send context in fetch. Handle `spend_filter` in response by calling the callback.
- **`vendors/src/App.tsx`**: Pass new props to ChatPanel. Implement `handleSpendFilterUpdate` callback that applies set/add/remove on `selectedVendors`. Auto-fetch spend data after agent-driven filter updates using a ref flag to avoid triggering on manual dropdown changes.

## Key decisions

- No vendor names/IDs sent in context — just `view` + count. Agent uses existing tools for lookups.
- Vendor name/filter resolution happens server-side; frontend receives doc IDs and applies set operations.
- `spend_filter` is a new field on `ChatResponse`, not overloading the existing `pending_action`.
- No auto tab-switching; agent updates the filter silently, user navigates themselves.
- Auto-fetch after agent filter updates, gated by a ref flag.

## Acceptance criteria

- User can type "just show 1099 vendors" on the Spending tab and the chart re-renders with only 1099 vendors
- User can type "remove Michael Mader" on the Spending tab and that vendor is excluded from the chart
- User can type "add Interexy" on the Spending tab and that vendor is added to the chart filter
- When on the Vendors tab, "add X" creates a new vendor (existing behavior preserved)
- If the user's intent is ambiguous, the agent asks for clarification
- After an agent-driven filter update, spend data auto-fetches without the user clicking Fetch
- Manual dropdown changes do NOT trigger auto-fetch (existing behavior preserved)
