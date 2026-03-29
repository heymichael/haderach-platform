---
id: "86"
title: "Rename finance_admin role to vendor_admin"
status: pending
group: platform
phase: platform
priority: low
type: chore
tags: [admin-revamp, rename, rbac]
dependencies: ["85"]
effort: small
created: 2026-03-29
---

## Context

Task 85 renamed the admin-finance app to admin-vendors but intentionally kept the `finance_admin` Firestore role unchanged to limit blast radius. Now that the app is called "Vendor Administration", the role name `finance_admin` is a naming inconsistency.

Only 4 users currently hold this role, so the Firestore migration is trivial (manual update).

## What needs to happen

### Firestore (4 user docs)

Update the `roles` array in each user doc: `finance_admin` → `vendor_admin`.

Do this **before** deploying code changes so users don't lose access during the transition.

### Code changes (~16 occurrences across 4 repos)

| Repo | File | Change |
|------|------|--------|
| admin-vendors | `src/App.tsx` (3 sites) | `'finance_admin'` → `'vendor_admin'` |
| haderach-home | `packages/shared-ui/src/auth/app-catalog.ts` | `["finance_admin"]` → `["vendor_admin"]` |
| vendors | `src/auth/AuthGate.tsx` | `'finance_admin'` → `'vendor_admin'`, rename `isFinanceAdmin` → `isVendorAdmin` |
| agent | `service/app.py` (3 sites) | `FINANCE_ADMIN_ROLES`, role check, 403 message |
| agent | `service/tools.py` (2 sites) | Role check, `is_finance_admin` → `is_vendor_admin` |
| agent | `mcp_server/tools.py` (2 sites) | `is_finance_admin` → `is_vendor_admin` |
| agent | `tests/test_endpoints.py` (3 sites) | Test fixtures |
| agent | `tests/test_tools.py` (1 site) | Test fixture |

### Docs and tasks

Update prose references to `finance_admin` in admin-vendors README, docs/architecture.md, and any task files that reference the role name.

## Execution order

1. Update 4 Firestore user docs (manual)
2. Deploy code changes across all 4 repos
3. Verify access works end-to-end

## Notes

- No Terraform, CI, or Firebase config changes needed — purely application-level
- No dependency from other admin-revamp tasks (67, 77, 80) — can be done at any time
- The `isFinanceAdmin` field in the vendors AuthContext should also be renamed to `isVendorAdmin` for consistency
