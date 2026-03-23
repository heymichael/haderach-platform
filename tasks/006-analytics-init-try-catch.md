---
id: "006"
title: "Add defensive try-catch around analytics initialization"
status: cancelled
group: card
phase: card
priority: low
type: improvement
tags: [analytics]
created: 2026-03-12
---

# Add defensive try-catch around analytics initialization

## Purpose

`getAnalytics(app)` in `initAnalytics()` currently has no error handling. If it throws (e.g. in a restricted browser context, aggressive privacy settings, or a future SDK change), the error propagates through `getFirebaseAppInstance()` and could disrupt the auth flow. Analytics should degrade gracefully — never block the app.

## Approach

Wrap the `getAnalytics(app)` call in `src/analytics/analytics.ts` with a try-catch that logs a `console.warn` on failure and leaves the `analytics` variable `null`, so all subsequent `trackOnce`/`trackAlways` calls silently no-op via the existing `if (!analytics) return` guard.
