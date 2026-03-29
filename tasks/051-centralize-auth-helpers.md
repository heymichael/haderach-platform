---
id: "51"
title: "Centralize auth helpers and BaseAuthUser into shared-ui"
status: done
group: platform
phase: platform
priority: low
type: improvement
tags: [shared-ui, auth, deduplication, batch-bundle]
effort: small
created: 2026-03-23
---

## Purpose

Several auth primitives are duplicated across all app repos. Centralizing them in `@haderach/shared-ui` eliminates drift and makes the auth contract explicit.

### Duplicated functions

`fetchUserDoc`, `buildDisplayName`, and `normalizeEmail` are duplicated verbatim in `card/src/auth/accessPolicy.ts`, `stocks/src/auth/accessPolicy.ts`, `vendors/src/auth/accessPolicy.ts`, and `haderach-home/src/auth/use-auth.ts`. These functions are identical across all four apps and should live in `@haderach/shared-ui` alongside the app catalog (centralized in task 43).

### Duplicated `AuthUser` interface

Every app defines its own `AuthUser` interface in `src/auth/AuthUserContext.ts`. The common fields are identical:

```typescript
// duplicated in: vendors, card, stocks, admin-system, admin-vendors
export interface AuthUser {
  email: string
  photoURL?: string
  displayName?: string
  accessibleApps: NavApp[]
  accessibleAdminApps: NavApp[]
  signOut: () => void
  getIdToken: () => Promise<string>
}
```

Some apps extend this with app-specific fields (e.g. vendors adds `allowedDepartments`, `allowedVendorIds`, `deniedVendorIds`, `isFinanceAdmin` for spend filtering). The common base should be shared; app-specific extensions should remain local.

## Approach

### Part 1: Functions and types

1. Add `fetchUserDoc`, `buildDisplayName`, `normalizeEmail`, and the `UserDoc` interface to `@haderach/shared-ui` (e.g. `src/auth/user-doc.ts`).
2. Export from the barrel `src/index.ts`.
3. Update each app to import from `@haderach/shared-ui` and remove local copies.
4. Note: `fetchUserDoc` takes a `FirebaseApp` parameter, so `firebase/firestore` becomes a peer dependency of shared-ui (or the function is placed in a separate sub-export).

### Part 2: `BaseAuthUser` interface

`shared-ui` already has internal directory separation (`src/auth/`, `src/lib/`, `src/hooks/`, `src/components/`), so no new package is needed. `BaseAuthUser` goes into the existing `src/auth/` directory alongside the app catalog and role helpers.

1. Create `src/auth/base-auth-user.ts` in `@haderach/shared-ui` with the common interface:
   ```typescript
   import type { NavApp } from '../components/nav/types'

   export interface BaseAuthUser {
     email: string
     photoURL?: string
     displayName?: string
     accessibleApps: NavApp[]
     accessibleAdminApps: NavApp[]
     signOut: () => void
     getIdToken: () => Promise<string>
   }
   ```
2. Export from `src/index.ts`.
3. In each app, change `AuthUserContext.ts` to import and extend:
   ```typescript
   import type { BaseAuthUser } from '@haderach/shared-ui'

   // Apps with no extra fields can re-export directly
   export type AuthUser = BaseAuthUser

   // Apps with extensions (e.g. vendors) use interface extension
   export interface AuthUser extends BaseAuthUser {
     allowedDepartments: string[]
     allowedVendorIds: string[]
     deniedVendorIds: string[]
     isFinanceAdmin: boolean
   }
   ```
4. Shared components like `GlobalNav` can type their user prop against `BaseAuthUser`.

### Apps to update

| App | Local file | Extensions needed |
|---|---|---|
| haderach-home | `src/auth/use-auth.ts` | None — uses base fields only |
| card | `src/auth/AuthUserContext.ts` | None |
| stocks | `src/auth/AuthUserContext.ts` | None |
| vendors | `src/auth/AuthUserContext.ts` | `allowedDepartments`, `allowedVendorIds`, `deniedVendorIds`, `isFinanceAdmin` |
| admin-system | `src/auth/AuthUserContext.ts` | None |
| admin-vendors | `src/auth/AuthUserContext.ts` | None |
