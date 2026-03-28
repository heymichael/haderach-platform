---
id: "63"
title: "Chat-driven column visibility for vendor table"
status: pending
group: vendors
phase: vendors
priority: medium
type: feature
tags: [vendors, chat, agent, columns, table, ux, agent-strategy]
dependencies: []
---

## Context

The vendor table shows a fixed set of columns (Vendor, Account Type, Department, Owner, Hidden). Users should be able to change which columns are visible by chatting with the agent -- e.g. "just show me the bill.com ids" swaps the view to name + billcomId. The selection persists for the session but resets to defaults on page reload. No localStorage persistence.

## Approach

Add a `set_view_columns` agent tool so the LLM can respond to column-visibility requests. The data flow is:

1. User sends a chat message like "just show me bill.com ids"
2. Agent calls `set_view_columns(columns: ["billcomId"])`
3. Backend returns `view_columns: ["billcomId"]` in the chat response
4. Frontend updates table column visibility state

### Agent side (3 files)

- **agent/service/tools.py**: Add `set_view_columns` tool definition with `columns` (array of valid field keys) and `reset` (boolean to restore defaults). Handler validates keys and returns `{"ok": true, "action": "set_columns", "columns": [...]}`.
- **agent/service/app.py**: Add `view_columns: list[str] | None` to `ChatResponse`. Detect `action == "set_columns"` in tool-result parsing and pass columns through.
- **agent/service/prompts.py**: Add `set_view_columns` to tool list and add guidance: call it when the user asks to see specific fields or reset the view. The `name` column is always shown.

### Frontend side (4 files)

- **vendors/src/vendor-columns.tsx**: Define a `COLUMN_REGISTRY` mapping all 21 VendorInfo field keys to `ColumnDef` entries. Export `DEFAULT_COLUMNS = ["accountType", "department", "owner", "hide"]`. Change `buildVendorColumns` to accept `visibleKeys` and filter from the registry.
- **vendors/src/VendorList.tsx**: Accept `visibleColumns` prop, pass to `buildVendorColumns`, include in `useMemo` deps.
- **vendors/src/ChatPanel.tsx**: Add `view_columns` to `ChatResponse` interface. Add `onSetColumns` callback prop. Call it when response includes `view_columns`.
- **vendors/src/App.tsx**: Add `visibleColumns` state initialized to `DEFAULT_COLUMNS`. Pass to `VendorList` and wire `onSetColumns` to `ChatPanel`.

### Valid column keys (21)

`billcomId`, `paymentMethod`, `accountType`, `track1099`, `toolCall`, `lastSyncedAt`, `owner`, `secondaryOwner`, `department`, `purpose`, `spendType`, `hide`, `contractStartDate`, `contractEndDate`, `contractLengthMonths`, `autoRenew`, `renewalRate`, `renewalNoticeDays`, `billingFrequency`, `terminationTerms`, `created_at`, `modified_at`

## Acceptance criteria

- User can type "show me bill.com ids" and the table shows only Vendor + Bill.com ID columns
- User can type "reset to default" and the table restores the default 5-column view
- Column changes persist during the session (navigating between Vendors/Spending tabs and back)
- Column state resets on full page reload
- The `name` column is always visible regardless of what the agent sends
