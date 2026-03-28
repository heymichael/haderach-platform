---
id: "71"
title: "Migrate vendors app from direct Firestore to API-driven architecture"
status: pending
group: vendors
phase: platform
priority: medium
type: tech-debt
tags: [vendors, api, firestore, architecture, agent, vendor-components]
dependencies: ["65"]
effort: medium
created: 2026-03-28
---

Full implementation plan: `/Users/michaelmader_1/.cursor/plans/spend_rest_endpoint_0f7389de.plan.md`

## Purpose

The vendors app currently reads and writes Firestore directly from the client (via Firebase JS SDK). All other apps follow the service-oriented pattern: data flows through the agent service API, with no direct database access from frontends. This inconsistency creates several problems:

- **Security**: Client-side Firestore access requires permissive security rules; API-driven access lets the server enforce authorization.
- **Consistency**: Business logic (e.g., vendor resolution, spend filtering) lives in the agent service but is bypassed by direct Firestore calls.
- **Maintainability**: Two data access patterns means two sets of queries to maintain and debug.

## Current direct Firestore usage

The vendors app accesses Firestore directly in these areas:

1. **Vendor list/detail** — reads `vendors` collection directly via `useVendors()` hook
2. **Spend data** — reads `vendor_spend` collection directly via `fetchVendorSpend()`
3. **User auth context** — reads `users/{email}` doc directly in `accessPolicy.ts`
4. **Vendor mutations** — creates/updates/deletes vendor docs directly

## Target state

All data access goes through agent service API endpoints:

| Current (direct Firestore) | Target (API-driven) |
|---|---|
| `useVendors()` → Firestore `vendors` | `GET /agent/api/vendors` (exists) |
| `fetchVendorSpend()` → Firestore `vendor_spend` | New: `GET /agent/api/spend` |
| `accessPolicy.ts` → Firestore `users/{email}` | Already available via auth context |
| Vendor CRUD → Firestore directly | `PATCH /agent/api/vendors/{id}`, `DELETE /agent/api/vendors/{id}` (exist) |

## Migration steps

1. Add missing agent API endpoints (spend queries)
2. Replace direct Firestore reads with `agentFetch` calls (shared-ui utility)
3. Replace direct Firestore writes with API calls
4. Remove Firebase Firestore JS SDK dependency from vendors app
5. Tighten Firestore security rules (remove client-side read/write access for vendors data)

## Notes

- The `agentFetch` utility already exists in `@haderach/shared-ui` and is used by `admin-system`.
- Several vendor API endpoints already exist (`GET /vendors`, `PATCH /vendors/{id}`, `DELETE /vendors/{id}`).
- The main gap is a spend query API endpoint — the agent service currently only exposes spend data through MCP tool handlers (chat), not as a REST endpoint.
- This migration is a prerequisite for fully enforcing server-side spend filtering (task 65, workstream 4e).

## Acceptance criteria

- Vendors app makes zero direct Firestore calls
- All data flows through agent service API endpoints
- Firebase Firestore JS SDK removed from vendors app dependencies
- Existing functionality unchanged (vendor list, spend charts, vendor edit/delete)
- Firestore security rules tightened to deny direct client access to vendors/vendor_spend collections
