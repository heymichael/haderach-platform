---
id: 38
title: Refresh CROSS_REPO_PAT before expiry
group: platform
phase: platform
status: pending
priority: high
depends_on: []
due: 2026-05-31
---

# Refresh CROSS_REPO_PAT before expiry

## Context

A GitHub PAT (`CROSS_REPO_PAT`) is used by stocks and card CI workflows to clone the haderach-home repo for the `@haderach/shared-ui` file: dependency. This token has an expiry and must be rotated before it lapses, or CI will break silently.

## Acceptance criteria

- [ ] Generate a new PAT (or extend the existing one) before May 31, 2026
- [ ] Update the `CROSS_REPO_PAT` secret in the stocks repo
- [ ] Update the `CROSS_REPO_PAT` secret in the card repo
- [ ] Verify CI passes in both repos after rotation

## Notes

- This task becomes unnecessary once task #036 (publish shared-ui to GitHub Packages) is completed
