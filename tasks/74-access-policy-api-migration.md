---
id: "74"
title: "Migrate accessPolicy Firestore reads to API endpoint"
status: pending
group: platform
phase: platform
priority: high
type: improvement
tags: [access-policy, service-oriented-data-access, api, auth, tech-debt, batch-bundle]
dependencies: []
effort: medium
created: 2026-03-27
---

## Context

Every frontend app (vendors, stocks, admin-system, admin-finance) has an identical `src/auth/accessPolicy.ts` that reads the `users/{email}` document directly from Firestore via the Firebase client SDK to get roles, first name, and last name. This is the most widespread violation of the service-oriented data access rule.

The read happens after Firebase Auth is complete, so the user already has a valid ID token and can call an authenticated API endpoint instead.

## What needs to happen

- Add a `GET /agent/api/me` endpoint (or equivalent) to the agent service that:
  - Validates the Firebase ID token from the `Authorization` header
  - Reads the `users/{email}` document server-side
  - Returns `{ roles, firstName, lastName }`
- Update `accessPolicy.ts` in all four frontend repos to use `agentFetch` to call the new endpoint instead of importing from `firebase/firestore`
- Remove `firebase/firestore` imports from `accessPolicy.ts` in each repo
- Verify auth gate still works correctly in all apps after the migration

## Affected repos

- `vendors/src/auth/accessPolicy.ts`
- `stocks/src/auth/accessPolicy.ts`
- `admin-system/src/auth/accessPolicy.ts`
- `admin-finance/src/auth/accessPolicy.ts`
- `agent` (new endpoint)
