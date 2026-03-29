---
id: "75"
title: "Add dev-only Google sign-in to all app AuthGates"
status: done
group: platform
phase: platform
priority: low
type: improvement
tags: [auth, dev-experience, local-testing, batch-bundle]
effort: small
created: 2026-03-28
---

## Purpose

In local dev with `VITE_AUTH_BYPASS=false`, apps redirect unauthenticated users to the platform sign-in page (`/`). This causes a redirect loop because Firebase Auth state is per-origin and each app runs on its own port.

The vendors app now has a dev-only fix: when `import.meta.env.DEV` is true and no user is signed in, it shows a "Sign in with Google" button instead of redirecting. This lets the user authenticate directly on the app's origin. The code is stripped from production builds.

## What to do

Add the same pattern to the remaining apps:

| App | File | Port |
|---|---|---|
| admin-system | `src/auth/AuthGate.tsx` | 5175 |
| admin-vendors | `src/auth/AuthGate.tsx` | 5176 |
| stocks | `src/auth/AuthGate.tsx` | (check `.env`) |
| card | `src/auth/AuthGate.tsx` | (check `.env`) |

### Pattern (from vendors)

1. Import `GoogleAuthProvider` and `signInWithPopup` from `firebase/auth`
2. Add `'sign_in'` to the `AuthStatus` type
3. In the `onAuthStateChanged` callback, when `!nextUser`:
   - If `import.meta.env.DEV`: set status to `'sign_in'`
   - Else: redirect as before
4. Render a sign-in UI when `status === 'sign_in'`:
   ```tsx
   const handleDevSignIn = async () => {
     const app = getFirebaseAppInstance()
     if (!app) return
     setAuthBusy(true)
     try {
       await signInWithPopup(getAuth(app), new GoogleAuthProvider())
     } catch {
       setAuthBusy(false)
     }
   }
   ```

### Reference implementation

`vendors/src/auth/AuthGate.tsx` on the `feat/vendor-spend-access-filtering` branch.

## Also update

- Platform rule `local-dev-testing.mdc` — note that `VITE_AUTH_BYPASS=false` with real auth no longer requires haderach-home to be running (dev sign-in is self-contained per app).
