---
id: "64"
title: "Agent-driven spend filter control"
status: pending
group: vendors
phase: vendors
priority: medium
type: feature
tags: [vendors, chat, agent, spending, filter, context-awareness]
dependencies: []
---

## Context

The Spending graph's vendor filter is only controllable via the sidebar dropdown. Users should be able to describe what vendors they want included or excluded via the agent pane -- e.g. "remove Michael Mader", "Show Interexy", "Just show me 1099 vendors". The agent also needs tab context awareness so that "add X" is interpreted correctly on the Spending tab (add to chart filter) vs the Vendors tab (create a new vendor).

## Plan

Full implementation plan: `.cursor/plans/agent_spend_filter_control_14914001.plan.md`

## Approach

Add an `update_spend_filter` agent tool that resolves vendor names or filter criteria (e.g. `{"track1099": true}`) to Firestore document IDs and sends them back to the frontend as a set/add/remove operation on the chart's vendor selection. Inject the user's current tab context into the system prompt so the agent can disambiguate intent.

### Agent side (4 files)

- **agent/service/firestore_client.py**: Add `resolve_vendor_ids(names, filters)` that resolves vendor names via `resolve_vendor()` and/or queries the vendors collection with filters. Returns `{"vendor_ids": [...], "not_found": [...]}`.
- **agent/service/tools.py**: Add `update_spend_filter` tool definition with `action` (set/add/remove), optional `vendor_names` (list), optional `filters` (dict). Handler calls `resolve_vendor_ids` and returns resolved IDs.
- **agent/service/app.py**: Add `SpendFilterUpdate` model (action + vendor_ids) and extend `ChatResponse` with optional `spend_filter` field. Detect `action == "update_spend_filter"` in tool results. Inject `req.context` (view, selectedVendorCount) into system prompt.
- **agent/service/prompts.py**: Add `update_spend_filter` to tool list. Add "UI context awareness" section explaining how to interpret add/remove/show commands differently on Spending vs Vendors tabs. Instruct agent to ask when intent is ambiguous.

### Frontend side (2 files)

- **vendors/src/ChatPanel.tsx**: Add props for `view`, `selectedVendorCount`, `onSpendFilterUpdate`. Expand context in fetch call to include `view` and `selectedVendorCount`. Handle `spend_filter` in response by calling `onSpendFilterUpdate`.
- **vendors/src/App.tsx**: Pass new props to ChatPanel. Implement `handleSpendFilterUpdate` callback that applies set/add/remove on `selectedVendors`. Auto-fetch spend data after agent-driven filter updates (ref flag + useEffect to avoid auto-fetching on manual dropdown changes).

## Key decisions

- No vendor names/IDs sent in context -- just `view` + count. Model uses existing tools for lookups.
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
