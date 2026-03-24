---
id: "52"
title: "Upgrade GitHub Actions to Node.js 24-compatible versions"
status: pending
group: platform
phase: platform
priority: medium
type: maintenance
tags: [ci, github-actions, node24, deprecation]
effort: small
created: 2026-03-23
---

## Purpose

GitHub Actions runners will force Node.js 24 by default starting June 2, 2026. Several actions used across all app CI and publish workflows are pinned to versions that run on Node.js 20 and emit deprecation warnings:

- `actions/upload-artifact@v4`
- `google-github-actions/auth@v2`
- `google-github-actions/setup-gcloud@v2`

These must be upgraded to Node.js 24-compatible versions before the deadline to avoid workflow failures.

## Approach

1. Check each action's releases for versions that support Node.js 24.
2. Update all workflow files across all repos that reference these actions:
   - `haderach-home/.github/workflows/`
   - `card/.github/workflows/`
   - `stocks/.github/workflows/`
   - `vendors/.github/workflows/`
   - `haderach-platform/.github/workflows/`
3. Also audit for any other actions that may be affected (e.g. `actions/checkout@v4`, `actions/setup-node@v4`).
4. Test by running CI on a feature branch in one repo before rolling out to all.

## Deadline

June 2, 2026 — after this date, Node.js 20 actions will stop working by default.
