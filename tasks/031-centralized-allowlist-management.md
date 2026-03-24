---
id: "31"
title: "Centralize allowlist management at platform level"
status: completed
group: platform
phase: platform
priority: high
type: feature
tags: [auth, allowlist, cross-app]
effort: large
created: 2026-03-18
---

## Purpose / Objective

Move user allowlist management out of hardcoded arrays in each app's `accessPolicy.ts` into a centralized, auth-protected management function at the platform level. This enables managing permissions across all apps without requiring code changes, rebuilds, and redeploys.

## Current State

- **Card app** (`card/src/auth/accessPolicy.ts`): Hardcoded `APP_ALLOWED_EMAILS`, `DOCS_ALLOWED_EMAILS`, `APP_ALLOWED_DOMAINS`, `DOCS_ALLOWED_DOMAINS` arrays with per-surface (app, docs) policies.
- **Stocks app** (`stocks/src/auth/accessPolicy.ts`): Hardcoded `ALLOWED_EMAILS` and `ALLOWED_DOMAINS` arrays (single flat list).
- Adding/removing a user requires editing source, committing, building, publishing artifacts, and deploying -- per app.

## Approach / Acceptance Criteria

- [ ] Platform exposes an auth-protected API or admin function for managing allowlists (emails and domains, per app and per surface).
- [ ] Allowlist data is stored centrally (e.g., Firestore, Cloud Storage, or similar) -- not in app source code.
- [ ] Apps fetch their allowlist at runtime from the central source instead of using hardcoded arrays.
- [ ] Changes to the allowlist take effect without app redeployment.
- [ ] The management interface is protected behind authentication (e.g., Firebase Auth + admin role check).
- [ ] Supports the card app's per-surface model (app vs docs) and the stocks app's flat model.
- [ ] Fallback behavior if the central source is unreachable (fail closed or use cached list).
