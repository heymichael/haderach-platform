---
id: "43"
title: "Centralize APP_CATALOG and APP_GRANTING_ROLES into shared-ui"
status: pending
group: platform
phase: platform
priority: medium
type: improvement
tags: [shared-ui, rbac, app-catalog, deduplication]
effort: medium
created: 2026-03-22
---

## Purpose

`APP_CATALOG` and `APP_GRANTING_ROLES` are duplicated in every app repo (`haderach-home/src/auth/roles.ts`, `stocks/src/auth/accessPolicy.ts`, `vendors/src/auth/accessPolicy.ts`). When a new app is onboarded, each copy must be updated independently. Drift between copies causes bugs — e.g. the stocks app was missing the vendors entry, so the Applications dropdown lost vendors after navigating to stocks.

Centralizing these into `@haderach/shared-ui` (or a new `@haderach/auth-policy` package) provides a single source of truth and eliminates this class of bug.

## Approach

1. Add `APP_CATALOG` and `APP_GRANTING_ROLES` to `haderach-home/packages/shared-ui` and export them.
2. Add `getAccessibleApps` and `hasAppAccess` helpers alongside the catalog.
3. Update each app's `accessPolicy.ts` / `roles.ts` to import from the shared package instead of maintaining a local copy.
4. Keep app-specific constants (e.g. `APP_ID`, `APP_PATH`) local to each app.
5. Verify the Applications dropdown shows the correct apps in all three deployed apps.

## Plan

`haderach-home/.cursor/plans/centralize_app_catalog_a09fe4b6.plan.md`
