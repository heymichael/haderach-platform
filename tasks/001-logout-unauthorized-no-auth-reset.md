---
id: "1"
title: "Logout from unauthorized screen does not reset auth state"
status: completed
group: card
phase: card
priority: medium
type: bug
tags: ["auth", "thisone"]
created: 2026-03-12
owner: Michael
---

# Logout from unauthorized screen does not reset auth state

## Purpose

After signing in with a non-whitelisted account, the user sees the unauthorized screen. Clicking "Sign out" and then "Sign in" should re-open the Google auth popup so the user can try a different account. Instead, it immediately returns to the unauthorized screen without showing the popup, as if the previous session's auth state was not fully cleared.

## Approach

- Reproduce in an incognito window: sign in with a non-whitelisted Google account → unauthorized screen → click log out → click log in → observe it skips the Google popup and goes straight back to unauthorized.
- Investigate `AuthGate.tsx` and `docs-auth-gate.js` sign-out handlers to confirm `signOut()` fully clears Firebase auth state before the `onAuthStateChanged` listener re-fires.
- Likely fix: ensure the sign-out completes and the auth state listener correctly transitions to `signed_out` before allowing a new sign-in attempt. May need to guard against the listener firing with stale user state during the sign-out→sign-in transition.
