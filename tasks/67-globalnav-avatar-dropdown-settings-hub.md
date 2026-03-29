---
id: "67"
title: "GlobalNav avatar dropdown redesign and Settings hub SPA"
status: pending
group: platform
phase: platform
priority: high
type: feature
tags: ["uxredo", "globalnav", "shared-ui", "settings", "admin", "ux", "rbac", "admin-revamp"]
dependencies: ["65"]
effort: large
created: 2025-03-25
---

## Plan

Full implementation plan:

`/Users/michaelmader_1/.cursor/plans/globalnav_avatar_dropdown_redesign_a99a59ef.plan.md`

## Purpose

Redesign the GlobalNav right section to use a single avatar dropdown (profile info, Settings link, Log out) and build a lightweight Settings hub SPA at `/admin/` that serves as a navigation layer to the admin apps.

## Part 1: Avatar dropdown

Replace the current separate Admin dropdown + avatar + sign-out text with a single avatar-triggered dropdown:

- Top: avatar + display name + email
- Middle: Settings link (always visible, navigates to `/admin/`)
- Bottom: Log out (separated)

## Part 2: Settings hub

The Settings hub at `/admin/` is a **thin navigation shell**, not a content app. It does not own any admin functionality — it routes users to the admin apps that do.

Layout: GlobalNav header + a role-filtered list of admin domains. Each item is a simple link that does a full page navigation to the corresponding admin app:

- **System** → `/admin/system/` (visible to users with `admin` role) — user management, roles, app permissions
- **Vendors** → `/admin/vendors/` (visible to users with `finance_admin` role) — vendor access controls, spend permissions

The admin apps are named by the objects being permissioned, not the role doing the granting. User/role management lives entirely in admin-system (task 80), not in the Settings hub.

Auth: Settings link in the avatar dropdown is always visible. The Settings hub SPA itself gates by `admin` or `finance_admin` role.

## Prerequisite: Standardize app-level UI patterns

Before onboarding more SPAs, establish consistent Tier 2 conventions so new apps don't splinter visually:

- **DataTable as default** — new apps should use the shared `DataTable` component (TanStack Table wrapper) for all tabular data, not raw Table primitives.
- **Tier 2 color palette convention** — define whether admin/platform SPAs share a palette or each app picks its own.
- **Page layout baseline** — establish a standard page shell pattern (header + content area, optional sidebar) that new SPAs follow.

This doesn't block task 67 itself, but should be resolved before additional SPAs are scaffolded.

## Execution order (admin revamp)

1. **Task 85** — Rename admin-finance to admin-vendors
2. **Task 67 Part 1** — GlobalNav avatar dropdown (this task)
3. **Task 80 (Users + Roles)** — Add react-router-dom, extract UsersPage and RolesPage
4. **Task 77** — Dynamic app permissioning backend
5. **Task 80 (Apps page)** — Add AppsPage route once task 77 backend is ready
6. **Task 67 Part 2** — Settings hub SPA at `/admin/` (this task)

## Acceptance criteria

- Avatar dropdown replaces Admin dropdown + avatar + sign-out in GlobalNav across all apps
- Dropdown shows display name, email, Settings link, and Log out
- Settings hub at `/admin/` shows a role-filtered list of admin domains
- Clicking a domain navigates to the corresponding admin app (no embedding)
- Settings hub has no Users page — user management lives in admin-system (task 80)
