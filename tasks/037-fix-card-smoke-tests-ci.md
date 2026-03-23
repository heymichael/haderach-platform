---
id: 37
title: Fix card app smoke tests in CI
group: card
phase: card
status: cancelled
priority: medium
depends_on: []
---

# Fix card app smoke tests in CI

## Context

After integrating `@haderach/shared-ui` (GlobalNav) into the card app, the Playwright smoke tests in `ci.yml` are failing. The smoke test step has been marked `continue-on-error: true` so it doesn't block PRs. This task tracks fixing the tests and removing the `continue-on-error` flag.

## Acceptance criteria

- [ ] Investigate and fix the card app smoke test failures
- [ ] Remove `continue-on-error: true` from the smoke test step in `ci.yml`
- [ ] CI passes with smoke tests blocking again
