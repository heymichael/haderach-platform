---
id: "65"
title: "RBAC model, vendor spend access control, and admin apps"
status: in-progress
group: platform
phase: platform
priority: high
type: feature
tags: [rbac, auth, spend, permissions, firestore, admin, agent, vendors, shared-ui]
dependencies: []
effort: large
created: 2025-03-25
---

## Purpose

Replace the current `admin`/`member`/`*_member` role model with four stackable roles (`user`, `admin`, `finance_admin`, `haderach_user`), add vendor-level spend filtering, and build two admin SPAs for user and permission management.

## Full plan

Implementation details, file-level changes, code examples, and decided questions live in the canonical plan files:

- **Workstreams 0-3 (RBAC, auth, GlobalNav, System Admin):** `/Users/michaelmader_1/.cursor/plans/revised_rbac_and_admin_apps_502dbedf.plan.md`
- **Workstream 4 (vendor spend filtering, Finance Admin SPA, shared-ui components):** `/Users/michaelmader_1/.cursor/plans/workstream_4_vendor_access_6d5e7d65.plan.md`

## Role model (summary)

| Role | Regular apps | Vendor spend | Admin capabilities | Assigned by |
|---|---|---|---|---|
| `user` | stocks, vendors | Only `allowed_vendor_ids` | None | `admin` via UI |
| `admin` | stocks, vendors | Only `allowed_vendor_ids` | Create users, grant `user`/`admin` | `admin` via UI |
| `finance_admin` | None (needs `user`/`admin` too) | All spend (bypasses filtering) | Grant `allowed_vendor_ids` | Manual Firestore |
| `haderach_user` | card | N/A | None | Manual Firestore |

Roles are stackable. `admin` with no `allowed_vendor_ids` sees zero vendor spend. Only `finance_admin` bypasses filtering.

## Workstreams

### 0. Agent service auth foundation (prerequisite) — COMPLETED 2025-03-25

Add Firebase ID token verification to the agent service so that all endpoints have a verified caller identity. Without this, spend filtering and admin endpoints cannot be securely enforced.

- [x] Add `firebase-admin` to agent dependencies
- [x] Create auth middleware that verifies `Authorization: Bearer <idToken>` headers via Firebase Admin SDK
- [x] Extract verified email from the decoded token (replace client-supplied `userEmail` in context)
- [x] Apply middleware to all sensitive endpoints (`/chat`, `/users`, `/vendors`)
- [x] Default-deny: unauthenticated requests are rejected; missing identity = no spend access

Deployed to prod and verified: authenticated requests succeed, unauthenticated requests are rejected.

### 1. Shared auth infrastructure — COMPLETED 2025-03-25

- [x] Revise `app-catalog.ts` in shared-ui: update `APP_GRANTING_ROLES` with new role names, add `ADMIN_CATALOG` and `ADMIN_GRANTING_ROLES`
- [x] Add `getAccessibleAdminApps(roles)` helper
- [x] Update all consumer apps (haderach-home, vendors, stocks, card) for new role names
- [x] Update seed script with new roles (merge strategy — preserves old roles for safe cutover)
- [x] Seed Firestore with new roles for all 9 users

Deployed to prod. Old role names removed from Firestore.

### 2. GlobalNav admin section — COMPLETED 2025-03-26

- [x] Add `adminApps` prop to GlobalNav
- [x] Render Admin dropdown when user has `admin` or `finance_admin` role
- [x] Links to `/admin/system/` and `/admin/finance/`

### 3. System Administration SPA and agent endpoints — COMPLETED 2025-03-26

- [x] **System Administration SPA** — new Vite + React SPA at `/admin/system/` (`heymichael/system-admin`)
  - List users, create users, edit user name and roles, delete users
  - Auth-gated: requires `admin` role
  - Temporarily hides `haderach_user` role holders from display
- [x] **Agent service endpoints**
  - `GET /users` — list all users (optional multi-role filter)
  - `GET /users/{email}` — single user detail with resolved vendor names
  - `POST /users` — create user doc (requires `admin`)
  - `PATCH /users/{email}` — update roles and name (requires `admin`)
  - `DELETE /users/{email}` — delete user doc (requires `admin`)
- [x] **Platform config**
  - Firebase hosting rewrite for `/admin/system/**`
  - Admin-system added to single-app and batch deploy workflows
- [x] **Vendors app** — updated user query from `vendors_member` to `user`/`admin` roles
- [x] **haderach-home** — `returnToAppId` supports admin catalog apps

Deployed to prod. Old `stocks_member`/`vendors_member`/`card_member` roles cleaned from Firestore.

### 4. Vendor spend filtering, Finance Administration SPA, and related endpoints

- **Finance Administration SPA** — new Vite + React SPA at `/admin/finance/`
  - List users, manage `allowed_vendor_ids` per user via vendor multi-select
  - Auth-gated: requires `finance_admin` role
- **Agent service endpoints for vendor filtering**
  - `PATCH /users/{email}` — update `allowed_vendor_ids` (requires `finance_admin`)
  - `GET /vendors` — list vendor IDs/names for admin picker
  - `/chat` — use verified caller identity to load `allowed_vendor_ids`, filter spend tools
- **Vendors app spend filtering**
  - Add `allowedVendorIds` and `isFinanceAdmin` to `AuthUser` context
  - Filter spend data in `fetchVendorSpend.ts` by `allowedVendorIds`
  - Filter vendor multi-select in spending view to only show allowed vendors
  - Pass `userEmail` (and ID token) from ChatPanel to agent service
- **Platform config**
  - Firebase hosting rewrite for `/admin/finance/**`
- Update architecture docs in platform and vendors repos

**MCP server integration note:** The vendor analytics MCP server (being built separately) already accepts a `caller_context` parameter on all spend tool handlers with `allowed_vendor_ids` and `is_finance_admin`. When this workstream is implemented, the production agent tool wrappers in `service/tools.py` should populate `caller_context` from the verified caller's Firestore user doc before calling MCP tool functions. The MCP tools will filter spend results to `allowed_vendor_ids` (or bypass for `finance_admin`). Vendor-specific spend queries for unauthorized vendors should return `not_authorized` status; aggregate queries should silently scope to allowed vendors.

## Implementation order

1. Workstream 0 (agent auth foundation) — DONE
2. Workstream 1 (shared auth / role model) — DONE
3. Workstream 2 (GlobalNav admin navigation) — DONE
4. Workstream 3 (System Administration SPA + agent endpoints + platform config) — DONE
5. Workstream 4 (vendor spend filtering + Finance Administration SPA + related endpoints)

## Decided questions

1. `finance_admin` bypasses spend filtering; everyone else is restricted by `allowed_vendor_ids`
2. `finance_admin` and `haderach_user` are assigned manually (Firestore); `admin` can only grant `user` and `admin`
3. System Administration role picker is hardcoded (`user`, `admin` only)
4. Vendor list/detail views are unrestricted — only spend data is filtered
5. Client-side enforcement for now (Firestore security rules unchanged)

## Open questions

1. Migration path for existing users with `member`, `vendors_member`, etc. → `user` role (one-time script)

## Acceptance criteria

- Agent service verifies caller identity via Firebase ID token on all sensitive endpoints
- Unauthenticated requests to `/chat`, `/users`, `/vendors` are rejected
- Users with `finance_admin` role see all vendor spend data without restriction
- Users with `user` or `admin` roles only see spend for vendors in their `allowed_vendor_ids`
- Users with no `allowed_vendor_ids` (and without `finance_admin`) see no spend data
- The vendor multi-select in spending view only shows vendors the user is allowed to see
- Agent chat responses respect the same vendor-level filtering as the UI
- System Administration SPA allows `admin` users to create users and assign `user`/`admin` roles
- Finance Administration SPA allows `finance_admin` users to manage `allowed_vendor_ids` per user
- Documentation is updated in platform and vendors architecture docs
