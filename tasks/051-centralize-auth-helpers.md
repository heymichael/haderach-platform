---
id: "51"
title: "Centralize fetchUserDoc, buildDisplayName, normalizeEmail into shared-ui"
status: pending
group: platform
phase: platform
priority: low
type: improvement
tags: [shared-ui, auth, deduplication]
effort: small
created: 2026-03-23
---

## Purpose

`fetchUserDoc`, `buildDisplayName`, and `normalizeEmail` are duplicated verbatim in `card/src/auth/accessPolicy.ts`, `stocks/src/auth/accessPolicy.ts`, `vendors/src/auth/accessPolicy.ts`, and `haderach-home/src/auth/use-auth.ts`. These functions are identical across all four apps and should live in `@haderach/shared-ui` alongside the app catalog (centralized in task 43).

## Approach

1. Add `fetchUserDoc`, `buildDisplayName`, `normalizeEmail`, and the `UserDoc` interface to `@haderach/shared-ui` (e.g. `src/auth/user-doc.ts`).
2. Export from the barrel `src/index.ts`.
3. Update each app to import from `@haderach/shared-ui` and remove local copies.
4. Note: `fetchUserDoc` takes a `FirebaseApp` parameter, so `firebase/firestore` becomes a peer dependency of shared-ui (or the function is placed in a separate sub-export).
