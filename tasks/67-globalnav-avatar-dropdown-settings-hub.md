---
id: "67"
title: "GlobalNav avatar dropdown redesign and Settings hub SPA"
status: pending
group: platform
phase: platform
priority: high
type: feature
tags: [globalnav, shared-ui, settings, admin, ux, rbac]
dependencies: ["65"]
effort: large
created: 2025-03-25
---

## Plan

Full implementation plan:

`/Users/michaelmader_1/.cursor/plans/globalnav_avatar_dropdown_redesign_a99a59ef.plan.md`

## Purpose

Redesign the GlobalNav right section to use a single avatar dropdown (profile info, Settings link, Log out) and build a Settings hub SPA at `/admin/` with sidebar navigation for Users and Permissions management.

## Part 1: Avatar dropdown

Replace the current separate Admin dropdown + avatar + sign-out text with a single avatar-triggered dropdown:

- Top: avatar + display name + email
- Middle: Settings link (always visible, navigates to `/admin/`)
- Bottom: Log out (separated)

## Part 2: Settings SPA

New SPA at `/admin/` with simpler layout (GlobalNav + fixed left nav, no collapsible sidebar):

- **Users** — user list table with create/edit, role assignment (requires `admin`)
- **Permissions** — entry point to System Admin and Finance Admin SPAs

Auth: Settings link always visible; SPA itself gates by `admin` or `finance_admin` role.

## Acceptance criteria

- Avatar dropdown replaces Admin dropdown + avatar + sign-out in GlobalNav across all apps
- Dropdown shows display name, email, Settings link, and Log out
- Settings SPA at `/admin/` loads with left nav (Users, Permissions)
- Users view lists all users with ability to create and assign roles
- Permissions view provides access to System and Finance admin SPAs
