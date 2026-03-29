---
id: "65"
title: "RBAC model, vendor spend access control, and admin apps"
status: done
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
| `user` | stocks, vendors | Filtered by `allowed_departments` + `allowed_vendor_ids` - `denied_vendor_ids` | None | `admin` via UI |
| `admin` | stocks, vendors | Filtered by `allowed_departments` + `allowed_vendor_ids` - `denied_vendor_ids` | Create users, grant `user`/`admin` | `admin` via UI |
| `finance_admin` | None (needs `user`/`admin` too) | All spend (bypasses filtering) | Manage vendor access fields per user | Manual Firestore |
| `haderach_user` | card | N/A | None | Manual Firestore |

Roles are stackable. `admin` with no access fields sees zero vendor spend when filtering is enabled. Only `finance_admin` bypasses filtering.

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
- [x] Links to `/admin/system/` and `/admin/vendors/`

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

**Access model:** Two-tier — department-level grants + vendor-level overrides (include/exclude). Resolution: (vendors in `allowed_departments` UNION `allowed_vendor_ids`) MINUS `denied_vendor_ids`. Deny always wins. Vendors with no department are invisible unless explicitly granted. `finance_admin` bypasses all filtering.

**Feature flag:** `config/feature_flags.enforce_spend_filtering` in Firestore controls activation. When `false` (default), spend filtering is disabled. Flip to `true` to enable — no deploy required.

#### 4a. Agent service — access resolution and endpoints — COMPLETED 2025-03-27

- [x] Implement `_build_caller_context` with Firestore feature flag for safe rollout
- [x] Add `resolve_effective_vendor_ids` helper (department resolution + include/exclude)
- [x] Add `get_user_access_context` lightweight user doc reader
- [x] Add `get_feature_flag` reader for `config/feature_flags`
- [x] `GET /vendors` — authed (any role), returns full vendor field set including department
- [x] `PATCH /users/{email}` — `finance_admin` can modify `allowedDepartments`, `allowedVendorIds`, `deniedVendorIds`
- [x] `GET /users` and `GET /users/{email}` — include access fields in responses
- [x] Add `list_vendors` to firestore_client

Deployed to prod. Filtering disabled via feature flag (safe default).

#### 4b. Shared-UI admin components — COMPLETED 2025-03-27

- [x] `AdminModal` — generic modal shell (extracted from admin-system's duplicate modal pattern)
- [x] `MultiSelect` — searchable multi-select popover with custom item rendering
- [x] `UserTable` — configurable user list table built on Table/Card primitives
- [x] `TagBadge` — reusable pill/badge for roles, departments, vendor names
- [x] `agentFetch` — shared authenticated fetch utility (deduplicate from admin-system and vendors)
- [x] Unit tests — 39 tests across 5 suites (Vitest + React Testing Library)

#### 4c. System Admin SPA refactor — COMPLETED 2025-03-27

- [x] Refactor admin-system to consume shared-ui admin components (AdminModal, UserTable, TagBadge, agentFetch)
- [x] Remove bespoke modal shells, inline table, and local agentFetch
- [x] Verify all existing functionality unchanged
- [x] UX refinements: icon-only edit/delete buttons, remove redundant close/refresh, sticky headers, type-ahead search, color scheme alignment with vendors
- [x] Fix deploy workflow hosting path mapping (admin-system → admin/system)

#### 4d. Vendor Administration SPA — COMPLETED 2025-03-27

- [x] New Vite + React SPA at `/admin/vendors/` (fully service-oriented — no direct database access)
- [x] Auth-gated: requires `finance_admin` role
- [x] User list (filtered to `user`/`admin` holders) using shared `UserTable`
- [x] Per-user edit: department multi-select, vendor include picker, vendor deny picker (all using shared `MultiSelect`)
- [x] Vendor pickers show "Name (Department)" format
- [x] Department list extracted client-side from `GET /vendors` response
- [x] Save via `PATCH /users/{email}` with access fields

#### 4e. Vendors app spend filtering — COMPLETED 2025-03-28

- [x] Extend `AuthUser` context with `allowedDepartments`, `allowedVendorIds`, `deniedVendorIds`, `isFinanceAdmin`
- [x] Client-side resolution of effective vendor set in spending view (no extra API call)
- [x] Filter vendor multi-select dropdown to only show allowed vendors
- [x] Filter spend query results by allowed vendor set (defense in depth)
- [x] Dev-only Google sign-in button in AuthGate for local testing with real auth
- [x] Seed script for config/feature_flags document (`scripts/seed_feature_flags.py`)

#### 4f. Platform config — COMPLETED 2025-03-27

- [x] Firebase hosting rewrite for `/admin/vendors/**`
- [x] Add admin-vendors to deploy workflows (single-app, batch, redeploy-all)
- [x] Terraform: service account, WIF binding, GCS IAM for admin-vendors artifact publishing
- [ ] Update architecture docs in platform and vendors repos

#### 4g. Supporting tasks

- [x] Populate vendor `department` field via CSV load (481 vendors classified)
- [x] Create tech debt task: migrate vendors app from direct Firestore to API-driven architecture (task 71)
- [x] Create Cursor rule: frontend apps access data through service APIs, no direct database access

## Implementation order

1. Workstream 0 (agent auth foundation) — DONE
2. Workstream 1 (shared auth / role model) — DONE
3. Workstream 2 (GlobalNav admin navigation) — DONE
4. Workstream 3 (System Administration SPA + agent endpoints + platform config) — DONE
5. Workstream 4a (agent service access resolution + endpoints) — DONE
6. Workstream 4b (shared-ui admin components) — DONE
7. Workstream 4c (System Admin SPA refactor) — DONE
8. Workstream 4d (Finance Administration SPA) — DONE
9. Workstream 4e (vendors app spend filtering) — DONE
10. Workstream 4f (platform config + docs) — DONE (docs outstanding)
11. Workstream 4g (supporting tasks: vendor departments, tech debt, Cursor rule)

## Decided questions

1. `finance_admin` bypasses spend filtering; everyone else is restricted by the access model
2. `finance_admin` and `haderach_user` are assigned manually (Firestore); `admin` can only grant `user` and `admin`
3. System Administration role picker is hardcoded (`user`, `admin` only)
4. Vendor list/detail views are unrestricted — only spend data is filtered
5. Client-side enforcement for now (Firestore security rules unchanged)
6. Two-tier access model: `allowed_departments` + `allowed_vendor_ids` (additive) + `denied_vendor_ids` (subtractive); deny always wins
7. Vendors with no `department` field are invisible unless explicitly in `allowed_vendor_ids`
8. Department values are stable (~10); dynamic resolution at query time is fine
9. Access resolution happens in `_build_caller_context` — MCP tools receive a flat vendor ID set and are unaware of departments
10. Vendors app resolves effective vendor set client-side (no extra API call); Finance Admin SPA is fully API-driven
11. `GET /vendors` returns full field set, authed but unfiltered for now (designed for future caller-scoped filtering)
12. Finance Admin SPA shows only `user`/`admin` role holders
13. Department picker derived client-side from `GET /vendors` response (no separate endpoint)
14. Shared-ui admin components: `AdminModal`, `MultiSelect`, `UserTable`, `TagBadge`, `agentFetch`
15. System Admin SPA to be refactored to use shared-ui components
16. Feature flag (`enforce_spend_filtering`) controls activation — flippable in Firebase console without deploy

## Open questions

(None remaining)

## Acceptance criteria

- Agent service verifies caller identity via Firebase ID token on all sensitive endpoints
- Unauthenticated requests to `/chat`, `/users`, `/vendors` are rejected
- Users with `finance_admin` role see all vendor spend data without restriction
- Users with `user` or `admin` roles only see spend for vendors resolved from their `allowed_departments` + `allowed_vendor_ids` - `denied_vendor_ids`
- Users with no access fields (and without `finance_admin`) see no spend data when filtering is enabled
- The vendor multi-select in spending view only shows vendors the user is allowed to see
- Agent chat responses respect the same vendor-level filtering as the UI
- System Administration SPA allows `admin` users to create users and assign `user`/`admin` roles
- Finance Administration SPA allows `finance_admin` users to manage `allowed_departments`, `allowed_vendor_ids`, and `denied_vendor_ids` per user
- Spend filtering can be enabled/disabled via Firestore feature flag without deploy
- Documentation is updated in platform and vendors architecture docs
