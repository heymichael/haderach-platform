---
id: "029"
title: "Add Firebase Auth gate to stocks app"
status: pending
group: stocks
phase: stocks
priority: medium
type: feature
tags: [auth, firebase]
created: 2026-03-18
---

# Add Firebase Auth gate to stocks app

## Purpose

The stocks app currently has no authentication. Add a Firebase Auth gate so only authorized users can access the app, consistent with how auth works on the card app.

## Approach

Use the card app's auth implementation as the reference pattern:
- Add Firebase Auth dependency and config
- Implement an auth gate component that checks sign-in state before rendering the app
- Support Google sign-in with the same allowlist/authorization model used by card
- Ensure sign-out fully clears auth state (card had a bug with this — see task 001)
- Update `docs/architecture.md` to move "Auth gate (Firebase Auth)" from Deferred to the active architecture sections
