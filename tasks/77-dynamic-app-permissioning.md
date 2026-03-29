---
id: "77"
title: "Make app permissioning and labels configurable via Firestore"
status: pending
group: platform
phase: platform
priority: medium
type: feature
tags: [rbac, auth, admin, shared-ui, firestore, admin-revamp]
effort: medium
created: 2026-03-28
---

## Purpose

App definitions (id, label, path, granting roles) are currently hardcoded in `@haderach/shared-ui` at `src/auth/app-catalog.ts`. Changing an app's display label, adding a new app, or modifying which roles grant access requires a code change, shared-ui rebuild, and redeploy of every consuming app.

This should be data-driven — an `apps` collection in Firestore that the admin UI can manage directly.

## Current state

Hardcoded in `haderach-home/packages/shared-ui/src/auth/app-catalog.ts`:

```typescript
export const APP_CATALOG: NavApp[] = [
  { id: "card", label: "Card", path: "/card/" },
  { id: "stocks", label: "Commodities", path: "/stocks/" },
  { id: "vendors", label: "Vendors", path: "/vendors/" },
]

export const APP_GRANTING_ROLES: Record<string, string[]> = {
  card: ["haderach_user"],
  stocks: ["user", "admin"],
  vendors: ["user", "admin"],
}

export const ADMIN_CATALOG: NavApp[] = [
  { id: "system_administration", label: "System", path: "/admin/system/" },
  { id: "finance_administration", label: "Finance", path: "/admin/finance/" },
]

export const ADMIN_GRANTING_ROLES: Record<string, string[]> = {
  system_administration: ["admin"],
  finance_administration: ["finance_admin"],
}
```

Consumed by `hasAppAccess`, `getAccessibleApps`, `getAccessibleAdminApps`, and every app's `AuthGate`.

## Proposed Firestore schema

### Collection: `apps`

One document per app. Document ID = app ID.

```
apps/card
  label: "Card"
  path: "/card/"
  type: "app"                    # "app" or "admin"
  granting_roles: ["haderach_user"]
  sort_order: 1

apps/vendors
  label: "Vendors"
  path: "/vendors/"
  type: "app"
  granting_roles: ["user", "admin"]
  sort_order: 3

apps/system_administration
  label: "System"
  path: "/admin/system/"
  type: "admin"
  granting_roles: ["admin"]
  sort_order: 1
```

### Key fields

| Field | Type | Description |
|---|---|---|
| `label` | string | Display name in GlobalNav and admin UIs (changeable without code changes) |
| `path` | string | URL path prefix for the app |
| `type` | `"app"` \| `"admin"` | Determines which nav section the app appears in |
| `granting_roles` | string[] | Roles that grant access to this app |
| `sort_order` | number | Display order within its type group |

## Approach

### 1. Firestore collection + seed script

- Create `apps` collection with documents matching current hardcoded data
- Write a seed script (`agent/scripts/seed_apps.py`) to initialize from current values
- The agent service already has Firestore access

### 2. Agent API endpoints

- `GET /apps` — list all app definitions (used by admin UIs and potentially by apps at boot)
- `PATCH /apps/{id}` — update label, granting_roles, sort_order (requires `admin` role)
- Creating/deleting apps remains manual (Firestore console or seed script) since it involves code/infra changes

### 3. Admin System SPA — app management UI

- New view in admin-system: table of apps with inline editing for `label` and `granting_roles`
- Uses the existing `UserTable`/`AdminModal` patterns
- `admin` role required

### 4. Runtime resolution

- Apps fetch the app catalog from the agent API at boot (or embed it in the auth flow)
- `hasAppAccess`, `getAccessibleApps`, `getAccessibleAdminApps` operate on the fetched data instead of hardcoded constants
- Shared-ui still provides the helper functions, but they take the catalog as a parameter instead of importing it
- Cache the catalog client-side (localStorage or in-memory) with a reasonable TTL

### 5. Migration path

- Keep the hardcoded catalog as a fallback during transition
- If the API is unreachable, fall back to hardcoded values
- Once stable, remove the hardcoded catalog from shared-ui

## Benefits

- Change an app's display label (e.g. "Commodities" → "Stocks") without any code change or deploy
- Add role-based access for a new app without rebuilding shared-ui
- Admin users can manage app permissions through the System Admin UI
- Decouples app metadata from the shared-ui build cycle

## Execution order (admin revamp)

1. **Task 85** — Rename admin-finance to admin-vendors
2. **Task 67 Part 1** — GlobalNav avatar dropdown
3. **Task 80 (Users + Roles)** — Add react-router-dom, extract UsersPage and RolesPage
4. **Task 77** — Dynamic app permissioning backend (this task)
5. **Task 80 (Apps page)** — Add AppsPage route once task 77 backend is ready
6. **Task 67 Part 2** — Settings hub SPA at `/admin/`

## Considerations

- The `path` field should generally not be editable via UI — changing it would break routing
- App creation/deletion still requires corresponding infrastructure (Firebase rewrites, deploy workflows, etc.)
- Need to handle the bootstrap problem: apps need the catalog to render GlobalNav, but the catalog comes from the API
