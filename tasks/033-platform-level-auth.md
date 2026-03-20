---
id: "033"
title: "Centralize authentication at platform level with per-app permissions"
status: completed
group: platform
phase: platform
priority: high
type: feature
tags: [auth, platform, cross-app, permissions]
dependencies: ["031"]
effort: large
created: 2026-03-19
---

## Purpose / Objective

Move authentication from individual app auth gates to a single platform-level sign-in flow. Once authenticated at the platform level, the user's identity determines which apps and surfaces they can access. This eliminates per-app sign-in friction and enables centralized permission management.

## Current State

- Each app (card, stocks) has its own `AuthGate` component that independently initializes Firebase Auth and performs Google sign-in.
- Users sign in separately per app.
- Authorization is checked per-app against allowlists (centralized in Firestore after task 031).

## Approach / Acceptance Criteria

- [ ] Users sign in once at the platform level (e.g., at `haderach.ai` root or a shared auth page).
- [ ] Platform-level session/token carries the user's identity to app routes.
- [ ] Apps check the platform-issued identity instead of running their own Firebase Auth flows.
- [ ] Per-app and per-surface permissions are derived from the centralized allowlist (built in task 031).
- [ ] Unauthorized users see a clear message indicating which apps they can access.
- [ ] Consider evolving the Firestore schema from app-centric (`allowlists/{appId}`) to user-centric (`users/{email}` with allowed apps) if needed.
- [ ] Graceful handling when a user has access to some apps but not others.
