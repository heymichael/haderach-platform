---
id: "014"
title: "Define full local parity contract for multi-app platform testing"
status: pending
group: platform
phase: platform
priority: low
type: docs
tags: [testing, local-dev]
created: 2026-03-03
---

# Define full local parity contract for multi-app platform testing

## Purpose

Restore a predictable "full platform on localhost" workflow after moving from a monorepo to separate app repositories, so routing/docs/auth/indexing behavior can be validated end-to-end before deployment. This reduces integration surprises that are not caught by app-only local runs.

## Approach

Specify a documented local parity contract that defines how each app repo publishes local runtime/docs artifacts for this platform repo, where those artifacts must be placed under `hosting/public`, and how parity prep is executed from repo root before running the Firebase Hosting emulator. Include required commands, optional venv/docs generation prerequisites, route/path conventions per app, and a smoke-check checklist covering root, app runtime, app docs, and policy headers. Decide and document whether artifact handoff is done via copy/sync scripts, symlinks, or manifest-driven pull, and capture trade-offs so onboarding future apps stays consistent.
