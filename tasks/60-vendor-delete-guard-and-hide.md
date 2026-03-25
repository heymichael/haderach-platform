---
id: "60"
title: "Vendor delete guard for Bill.com vendors + hide flag for spend suppression"
status: completed
group: vendors
phase: vendors
priority: high
type: feature
tags: [agent, firestore, vendors, spend, ux]
dependencies: ["56"]
effort: small
created: 2026-03-24
---

# Vendor delete guard for Bill.com vendors + hide flag for spend suppression

## Part 1 — Delete guard

Prevent deletion of Bill.com-synced vendors (docs with a `billcomId`). These are managed by the nightly sync — deleting them from Firestore would just result in re-creation on the next sync run.

### Changes

**`execute_delete_vendor` in `tools.py`**: After resolving the vendor, check for `billcomId`. If present, return an error message instead of the `confirm_delete` action. Message should tell the user the vendor is Bill.com-managed and suggest hiding it instead.

**`DELETE /vendors/{vendor_id}` in `app.py`**: Same guard — check for `billcomId` before deleting. Return 400 with explanation.

**System prompt in `prompts.py`**: Update the "Deleting vendors" section to mention the guard so the LLM doesn't repeatedly retry deletion of synced vendors.

Only manually-added vendors (no `billcomId`) should be deletable.

## Part 2 — Hide flag

Add a `hide` boolean field on vendor docs in the `vendors` collection. When `true`, the vendor is excluded from spend analysis. This is app-managed — never overwritten by the Bill.com vendor sync (which uses `merge=True` on synced fields only).

### Agent tool

Add a `hide_vendor` tool that toggles the `hide` boolean directly (no modal). Allows "hide Rhonda" as a one-liner in chat. Also add corresponding prompt guidance.

### Filtering — `search_vendors`

Filter out hidden vendors by default. Add an `include_hidden` parameter for cases where the user explicitly wants to see them (e.g. "show me hidden vendors", or when searching by name to un-hide).

### Filtering — `query_spend`

Use a **live filter** for immediate effect: before running the spend query, fetch the set of hidden vendor IDs from the `vendors` collection (`where("hide", "==", True)`). Exclude those vendorIds from the `vendor_spend` results in Python. The hidden list is likely small so the extra query is cheap.

Also add `hide` to `DENORMALIZED_FIELDS` in `sync_billcom_spend.py` as a belt-and-suspenders optimization — but the live filter is the primary mechanism so hiding takes effect immediately (not just after the next sync run).

### Where `hide` does NOT apply

- `search_vendors` still returns hidden vendors when explicitly searched by name (so the user can find and un-hide them). Only the default list view filters them out.
- The Bill.com vendor sync (`sync_billcom.py`) ignores `hide` — it still syncs metadata for hidden vendors.
- `execute_python` (live API queries) is unaffected — the LLM writes its own code.

## Validation

- Attempt to delete a Bill.com vendor → blocked with message suggesting hide
- Attempt to delete a manually-added vendor → works as before
- Hide a vendor → immediately excluded from `query_spend` results
- Hide a vendor → excluded from default `search_vendors` results
- Search for a hidden vendor by name → still found (so it can be un-hidden)
- Un-hide a vendor → immediately re-included in spend analysis
