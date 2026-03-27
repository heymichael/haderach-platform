# Agent-driven spend filter control

`/Users/michaelmader_1/haderach_org/haderach_site/haderach-platform/tasks/64-agent-spend-filter-control.md`

## Overview

Let users control the Spending chart's vendor filter via the chat agent — e.g. "just show 1099 vendors", "remove Michael Mader", "add Interexy". The agent must also be tab-context-aware so "add X" is interpreted as "add to chart filter" on the Spending tab vs "create a new vendor" on the Vendors tab.

## What already exists (from task 68)

The MCP server module (`agent/mcp_server/`) provides all the resolution and validation infrastructure this task needs:

- **`resolver.resolve_vendor(identifier)`** — resolves names, aliases, IDs, partial matches → `ok` / `ambiguous` / `not_found`
- **`resolver.validate_filters(filters)`** — validates enum and dynamic filter fields → `None` (all valid) or first `invalid_filter` response
- **Response contract** — `ok`, `ambiguous`, `not_found`, `invalid_filter` statuses are already understood by the LLM via the system prompt

No new resolution or validation logic needs to be written.

## Deliverables

### 1. New tool handler: `handle_update_spend_filter` in `agent/mcp_server/tools.py`

Accepts:
- `action`: `"set"` | `"add"` | `"remove"` — what to do with the resolved vendor IDs
- `vendor_names`: optional list of strings — vendor names/aliases/IDs to resolve
- `filters`: optional dict — filter criteria (e.g. `{"track1099": true}`) to query matching vendor IDs

Logic:
1. If `vendor_names` provided, loop through each calling `resolve_vendor()`. If any return `ambiguous` or `not_found`, return that status immediately so the LLM can ask the user.
2. If `filters` provided, call `validate_filters()`. If invalid, return the `invalid_filter` response. Otherwise, query the vendors collection with those filters and collect matching doc IDs.
3. Combine resolved IDs from both paths (union).
4. Return `{"status": "ok", "action": "set|add|remove", "vendor_ids": [...], "vendor_count": N}`.

This follows the exact same pattern as the existing six tool handlers.

### 2. Tool schema in `agent/service/tools.py`

Add `update_spend_filter` to `TOOL_DEFINITIONS` with the parameters above. Add the handler wrapper to `TOOL_HANDLERS`, following the same thin-wrapper pattern as the analytics tools.

### 3. Extend `ChatResponse` in `agent/service/app.py`

Add a new optional field to the response model:

```python
class SpendFilterUpdate(BaseModel):
    action: str          # "set" | "add" | "remove"
    vendor_ids: list[str]

class ChatResponse(BaseModel):
    reply: str
    tool_calls_executed: list[str]
    pending_action: PendingAction | None = None
    spend_filter: SpendFilterUpdate | None = None
```

In the tool-call loop, detect when `update_spend_filter` is called and its result has `status == "ok"`. Extract `action` + `vendor_ids` into the `spend_filter` field on the response.

### 4. Inject tab context into system prompt — `agent/service/app.py`

The frontend already sends `context: { app: 'vendors' }`. Extend this to include `view` and `selectedVendorCount`. In `app.py`, append a short context line to the system prompt:

```python
if req.context:
    ctx_parts = []
    if req.context.get("view"):
        ctx_parts.append(f"User is on the {req.context['view']} tab.")
    if req.context.get("selectedVendorCount") is not None:
        ctx_parts.append(f"{req.context['selectedVendorCount']} vendors currently selected in the chart filter.")
    if ctx_parts:
        system_prompt += "\n\n## Current UI context\n\n" + " ".join(ctx_parts)
```

### 5. Update system prompt — `agent/service/prompts.py`

- Add `update_spend_filter` to the tool table with description: "Updating the Spending chart's vendor filter (set/add/remove vendors by name or filter criteria)"
- Add a "UI context awareness" section:

```
## UI context awareness

When the user is on the **Spending** tab:
- "add X" / "show X" / "include X" → update_spend_filter(action="add", vendor_names=["X"])
- "remove X" / "hide X" / "exclude X" → update_spend_filter(action="remove", vendor_names=["X"])
- "just show 1099 vendors" → update_spend_filter(action="set", filters={"track1099": true})
- "show all vendors" → update_spend_filter(action="set") with no names or filters (resets to all)

When the user is on the **Vendors** tab:
- "add X" → add_vendor (create a new vendor)
- If intent is ambiguous (no tab context, or phrasing is unclear), ask the user.
```

### 6. Frontend: `vendors/src/ChatPanel.tsx`

- Accept new props: `view`, `selectedVendorCount`, `onSpendFilterUpdate`
- Send `view` and `selectedVendorCount` in the `context` object of the fetch body
- Handle `spend_filter` in the response: if present, call `onSpendFilterUpdate(data.spend_filter)`

### 7. Frontend: `vendors/src/App.tsx`

- Pass `view`, `selectedVendors.length`, and a `handleSpendFilterUpdate` callback to `ChatPanel`
- Implement `handleSpendFilterUpdate`:
  - `set` → `setSelectedVendors(update.vendor_ids)`
  - `add` → `setSelectedVendors(prev => [...new Set([...prev, ...update.vendor_ids])])`
  - `remove` → `setSelectedVendors(prev => prev.filter(id => !update.vendor_ids.includes(id)))`
- Auto-fetch after agent-driven filter updates: use a ref flag (`agentFilterUpdate.current = true`) that triggers `handleFetch` via a `useEffect` watching `selectedVendors`, but only when the ref flag is set. Reset the flag immediately. This avoids auto-fetching on manual dropdown changes.

## Files changed

| File | Repo | Change |
|------|------|--------|
| `mcp_server/tools.py` | agent | Add `handle_update_spend_filter` |
| `service/tools.py` | agent | Add tool schema + handler wrapper |
| `service/app.py` | agent | Add `SpendFilterUpdate` model, extend `ChatResponse`, inject tab context |
| `service/prompts.py` | agent | Add tool to table, add UI context awareness section |
| `src/ChatPanel.tsx` | vendors | Send context, handle `spend_filter` response |
| `src/App.tsx` | vendors | Wire callback, apply filter updates, auto-fetch |

## Key decisions

- No vendor names/IDs sent in context — just `view` + count. The agent uses existing tools for lookups.
- Vendor name/filter resolution happens server-side via existing `resolve_vendor()` and `validate_filters()`. Frontend receives doc IDs only.
- `spend_filter` is a new field on `ChatResponse`, separate from `pending_action`.
- No auto tab-switching — the agent updates the filter, user navigates themselves.
- Auto-fetch is gated by a ref flag so only agent-driven filter updates trigger it.
- "Show all vendors" (reset) is `action="set"` with no names or filters — handler returns all non-hidden vendor IDs.

## Acceptance criteria

- "just show 1099 vendors" on Spending tab → chart re-renders with only 1099 vendors
- "remove Michael Mader" on Spending tab → vendor excluded from chart
- "add Interexy" on Spending tab → vendor added to chart filter
- "add X" on Vendors tab → creates a new vendor (existing behavior preserved)
- Ambiguous intent → agent asks for clarification
- Agent-driven filter update → spend data auto-fetches
- Manual dropdown changes → no auto-fetch (existing behavior preserved)
