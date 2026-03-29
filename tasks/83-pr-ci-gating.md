---
id: "83"
title: "Add PR CI checks and branch protection to prevent premature merges"
status: pending
group: platform
phase: agent
---

## Problem

PRs can be merged before CI fixes are pushed. Both `agent` and `vendors` repos
only have a `publish-artifact` workflow that runs on push to `main`, with no
checks on PR branches. This has caused the same issue twice: a PR gets merged,
then a fix commit is pushed to the branch after the merge, requiring a
cherry-pick to `main`.

## Approach

1. Add a `ci.yml` workflow to both `agent` and `vendors` repos that runs on
   `pull_request` targeting `main`:
   - **vendors**: `npm ci && npm run build` (type-check + vite build)
   - **agent**: `pip install -r requirements.txt && python -m py_compile` on
     key service files
2. Enable GitHub branch protection on `main` for both repos requiring the CI
   check to pass before merge.

## Repos affected

- `agent`
- `vendors`
- Consider applying the same pattern to `haderach-home`, `admin-system`,
  `admin-finance`
