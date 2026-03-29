---
id: "80"
title: "Convert admin-system to multi-page app with Users, Roles, and App Permissions pages"
status: pending
group: platform
phase: platform
priority: high
type: feature
tags: [admin-revamp, admin, rbac, shared-ui]
dependencies: ["77"]
effort: medium
created: 2026-03-28
---

## Purpose

admin-system is currently a single-screen SPA (no router, one view + modals) that handles both user CRUD and role assignment in one combined interface. It needs to expand into a multi-page app that manages all system-level administration: users, roles, and app permissions.

The admin apps are named by the **objects being permissioned**, not the role doing the granting:

- **admin-system** — system-level things: users, roles, which apps each role can access. Gated by `admin` role.
- **admin-vendors** (currently `admin-finance`, rename tracked in task 85) — vendor-level things: vendor access controls, spend permissions. Gated by `finance_admin` role.

These stay as separate apps with separate auth gates for security boundary reasons: different permission requirements, different data sensitivity, independent deploy cadence.

The Settings hub (task 67) is a lightweight navigation shell at `/admin/` that routes users to these admin apps via a role-filtered list. It does not own any admin functionality — admin-system owns all user/role/app management.

## Why multi-page (not separate SPAs)

- **Same permission boundary** — all pages require the `admin` role, so they share one AuthGate
- **Shared data domain** — users, roles, and app permissions are tightly related; a single app can share API caches and avoid redundant fetches
- **Reduced infrastructure overhead** — one repo, one CI pipeline, one artifact, one deploy entry
- **Seamless navigation** — in-app routing instead of full page reloads between related admin views

## Architecture

```
Settings hub (/admin/)           admin-system (/admin/system/)
+------------------------+      +------------------------------------------+
|                        |      | [Logo]    Applications    [Avatar]       |
| Role-filtered list:    |      +------------------------------------------+
|                        |      |            |                             |
| > System  ------------|----->|  Users  *  |  (active page content)      |
| > Vendors  ------+    |      |            |                             |
|                   |    |      |  Roles     |                             |
+-------------------+----+      |            |                             |
                    |           |  Apps      |                             |
                    v           +------------------------------------------+
           admin-vendors
           (/admin/vendors/)
```

## Route structure

| Route | Page | Description |
|---|---|---|
| `/admin/system/` | Users | User list with create/edit/delete. Default landing page. |
| `/admin/system/roles` | Roles | Role assignment per user. View and modify which roles each user has. |
| `/admin/system/apps` | App Permissions | Manage which roles grant access to which apps (UI for task 77's Firestore-backed app catalog). |

## Page details

### Users page (`/admin/system/`)

The current admin-system view, extracted into its own route component. This is the primary landing page when navigating from the Settings hub.

- **User list table** — email, display name, current roles. Uses shared `DataTable` component.
- **Create user** — form/modal to create a new Firestore user doc with initial role assignment.
- **Edit user** — inline or modal editing for display name, email.
- **Delete user** — remove a user doc (with confirmation).
- Backed by agent service endpoints: `GET /users`, `POST /users`, `PATCH /users/{email}`, `DELETE /users/{email}`.

### Roles page (`/admin/system/roles`)

Breaks role assignment out of the current combined user detail view into a dedicated surface.

- **User-role matrix or list** — shows each user and their assigned roles.
- **Assign/remove roles** — toggle roles per user (e.g., `user`, `admin`, `finance_admin`).
- **Bulk operations** — optionally allow multi-select for batch role changes.
- Backed by the same `PATCH /users/{email}` endpoint (updating the `roles` array).

### App Permissions page (`/admin/system/apps`)

New page — the UI for task 77's dynamic app permissioning. Depends on task 77 backend being ready.

- **App list** — shows all registered apps with their current granting roles.
- **Edit app permissions** — modify which roles grant access to each app.
- **Add/remove apps** — manage the app catalog itself.
- Backed by `GET /apps` and `PATCH /apps/{id}` endpoints (task 77).

## Approach

### 1. Add react-router-dom

Install `react-router-dom` in admin-system. No platform-level changes needed — Firebase Hosting already rewrites `/admin/system/**` to `/admin/system/index.html`, and Vite's `base` is already `/admin/system/`.

### 2. Create layout shell

Break the current monolithic `App` component into:

- **`AppLayout`** — GlobalNav header + left sidebar nav + content area. The sidebar has three nav items (Users, Roles, Apps) and highlights the active route.
- **`UsersPage`** — the current user table + create dialog, extracted.
- **`RolesPage`** — role assignment UI, extracted from the current user detail modal.
- **`AppsPage`** — app permission management (new, depends on task 77).

Align with the layout conventions from task 67's "Standardize app-level UI patterns" prerequisite.

### 3. Incremental delivery

Users and Roles pages can ship independently of the Apps page. The Apps page depends on task 77's backend endpoints, so it can be added as a follow-up route once those are ready.

## Dependencies

- **Task 77** (dynamic app permissioning) — the Apps page needs the `GET /apps` and `PATCH /apps/{id}` endpoints. Users and Roles pages can ship first.
- **Task 67** (Settings hub) — the Settings hub's "System" link navigates to `/admin/system/`. These tasks are complementary, not overlapping.
- **Task 85** (rename admin-finance to admin-vendors) — naming alignment for the admin app model.

## Execution order (admin revamp)

1. **Task 85** — Rename admin-finance to admin-vendors
2. **Task 67 Part 1** — GlobalNav avatar dropdown
3. **Task 80 (Users + Roles)** — Add react-router-dom, extract UsersPage and RolesPage (this task)
4. **Task 77** — Dynamic app permissioning backend
5. **Task 80 (Apps page)** — Add AppsPage route once task 77 backend is ready (this task)
6. **Task 67 Part 2** — Settings hub SPA at `/admin/`

## Acceptance criteria

- admin-system uses react-router-dom with defined routes
- Users page shows user list with create/edit/delete functionality (current behavior preserved and improved)
- Roles page provides dedicated role assignment per user
- App Permissions page lets admins manage app-to-role mappings (once task 77 backend is ready)
- Left sidebar navigation allows switching between pages without full reload
- Layout follows shared-ui conventions (DataTable, consistent page shell)
- No changes required to firebase.json, deploy workflows, or platform infrastructure
