---
id: "82"
title: "[BUG] HTTP 414 on spend page — top-30 vendor grouping fix"
status: completed
group: vendors
phase: agent
---

## Plan

`/Users/michaelmader_1/haderach_org/haderach_site/haderach-platform/.cursor/plans/agent_spend_filter_control_14914001.plan.md`

## Problem

With 900+ vendors, the `GET /spend` endpoint received all vendor IDs as query
parameters, exceeding the URL length limit and returning HTTP 414 URI Too Long.

## Solution

### Backend (agent)

- Made `vendor_ids` optional on `GET /spend` — when omitted, returns spend for
  all vendors the caller has access to.
- Added `vendorId` to spend response rows so the frontend can filter by document
  ID rather than display name.

### Frontend (vendors)

- URL threshold (30): if more than 30 vendor IDs would be sent, the frontend
  omits `vendor_ids` from the request and filters the response client-side.
- Visualization threshold (30): after fetch, vendors are ranked by total spend
  across the date range. Only the top 30 are shown individually; the rest are
  grouped into an "Other" bucket in neutral gray.
- Chart height is now responsive to the viewport instead of a fixed 750px.
- Stacked bars sorted largest-at-bottom by total spend.
- Visual polish: 65% opacity on non-hovered series, reset on bar leave, always-
  visible inline labels, removed chart border and top padding.

## PRs

- Agent: https://github.com/heymichael/agent/pull/16
- Vendors: https://github.com/heymichael/vendors/pull/14

## Constants

- `VENDOR_URL_THRESHOLD` in `vendors/src/fetchVendorSpend.ts`
- `MAX_VENDORS` in `vendors/src/groupSpendRows.ts`
- Documented in `agent/docs/architecture.md` under "Spend visualization threshold"
