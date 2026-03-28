---
id: "80"
title: "Convert admin-system to multi-page app with User Management and App Permissions pages"
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

admin-system is currently a single-screen SPA (no router, one view + modals) that handles both user CRUD and role assignment in one combined interface. As we add app permissioning (task 77) and break user management out from role management, the app needs proper client-side routing to support multiple pages.

This is the first multi-page app in the platform. The decision to go multi-page here (rather than spinning up separate SPAs) is driven by:

- **Same permission boundary** — all pages require the `admin` role, so they share one AuthGate config
- **Shared data domain** — users, roles, and app permissions are tightly related; a single app can share API caches and avoid redundant fetches
- **Reduced infrastructure overhead** — one repo, one CI pipeline, one artifact, one deploy entry instead of three
- **Seamless navigation** — in-app routing instead of full page reloads between related admin views

admin-finance stays as a separate app because it has a distinct permission requirement (`finance_admin`), deals with sensitive spend data, and benefits from an independent security boundary and deploy cadence.

## Approach

### 1. Add react-router-dom

Install `react-router-dom` in admin-system. No platform-level changes needed — Firebase Hosting already rewrites `/admin/system/**` to `/admin/system/index.html`, and Vite's `base` is already `/admin/system/`.

### 2. Create route structure

| Route | Page | Description |
|---|---|---|
| `/admin/system/` | Users | User list with create/edit (current main view, extracted) |
| `/admin/system/roles` | Roles | Role assignment per user (broken out from current combined view) |
| `/admin/system/apps` | App Permissions | Manage which roles grant access to which apps (UI for task 77's Firestore-backed app catalog) |

### 3. Add page navigation

Add a sidebar or tab navigation within the app layout. All pages share the GlobalNav header and the sidebar/tab bar. Consider aligning with the layout conventions discussed in task 67's "Prerequisite: Standardize app-level UI patterns" section.

### 4. Refactor existing views

Break the current monolithic `App` component into:
- A layout shell (GlobalNav + sidebar + content area)
- A `UsersPage` component (the current user table + create dialog)
- A `RolesPage` component (role assignment UI, extracted from user detail)
- An `AppsPage` component (app permission management, new — depends on task 77 API endpoints)

### 5. Update shared-ui references if needed

The app catalog in `@haderach/shared-ui` references admin-system as a single entry. No changes needed there since the route prefix (`/admin/system/`) stays the same.

## Dependencies

- **Task 77** (dynamic app permissioning) — the Apps page needs the `GET /apps` and `PATCH /apps/{id}` endpoints to be useful. Users and Roles pages can ship independently.

## Related tasks

- **Task 67** (GlobalNav avatar dropdown + Settings hub) — the Settings hub concept overlaps with admin-system's expanded role. These tasks should be coordinated so the GlobalNav "Settings" link points to `/admin/system/` rather than a separate `/admin/` SPA.

## Acceptance criteria

- admin-system uses react-router-dom with defined routes
- Users page shows user list with create/edit functionality (current behavior preserved)
- Roles page provides role assignment per user
- App Permissions page lets admins manage app-to-role mappings (once task 77 backend is ready)
- Sidebar/tab navigation allows switching between pages without full reload
- No changes required to firebase.json, deploy workflows, or platform infrastructure
