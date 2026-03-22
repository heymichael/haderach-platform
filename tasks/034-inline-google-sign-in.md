---
id: "034"
title: "Replace sign-in popup with inline Google Identity Services"
status: cancelled
group: platform
phase: platform
priority: medium
type: improvement
tags: [auth, ux, platform]
dependencies: ["033"]
effort: small
created: 2026-03-19
---

## Purpose / Objective

Replace the `signInWithPopup` flow on the platform landing page with Google Identity Services (GIS) to render sign-in inline as a modal/overlay instead of opening a separate browser window. This provides a smoother, less disruptive sign-in experience.

## Current State

- The platform landing page at `haderach.ai/` uses Firebase Auth's `signInWithPopup` with `GoogleAuthProvider`.
- This opens a separate browser window for Google account selection.
- After selection, the popup closes and the landing page picks up the auth state.

## Approach / Acceptance Criteria

- [ ] Load the GIS client library (`https://accounts.google.com/gsi/client`) on the platform landing page.
- [ ] Replace the "Sign in with Google" button with GIS One Tap or the rendered Sign In With Google button.
- [ ] On credential callback, exchange the GIS ID token for a Firebase Auth credential via `GoogleAuthProvider.credential()` and `signInWithCredential()`.
- [ ] Verify the RBAC role-check flow still works identically after sign-in.
- [ ] No changes needed in app repos — only the platform landing page is affected.
- [ ] Ensure `localhost` works for local dev testing (GIS requires authorized JavaScript origins in the Google Cloud Console).
