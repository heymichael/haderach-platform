---
id: "78"
title: "Extract tasks into a dedicated repo"
status: pending
group: platform
phase: platform
priority: medium
type: chore
tags: [dev-experience, repo-structure]
effort: small
created: 2026-03-28
---

## Purpose

Task markdown files currently live in `haderach-platform/tasks/`. Once branch protection is enabled on `haderach-platform`, every task update (priority change, status change, new tag) would require a PR and CI pass. Tasks are project management artifacts, not code — they should be pushable without triggering deployment pipelines.

## Approach

1. Create a new repo `heymichael/haderach-tasks` with no CI/CD workflows
2. Move all files from `haderach-platform/tasks/` into the new repo root
3. Update `todo-conventions.mdc` in every app repo to point to `../haderach-tasks/` instead of `../haderach-platform/tasks/`
4. Update the taskmd startup command in conventions (e.g., `taskmd web start --dir ../haderach-tasks/`)
5. Remove `tasks/` directory from `haderach-platform`
6. Verify taskmd web dashboard and all Cursor rules resolve correctly

## Affected repos

- `haderach-platform` — remove `tasks/`, update any internal references
- `admin-system` — update `todo-conventions.mdc`
- `admin-finance` — update `todo-conventions.mdc`
- `vendors` — update `todo-conventions.mdc` (if present)
- `haderach-home` — update `todo-conventions.mdc` (if present)
- `agent` — update `todo-conventions.mdc` (if present)

## Notes

- Task file format, naming, and frontmatter remain unchanged
- No impact on taskmd functionality — just a different `--dir` path
- Enables branch protection on `haderach-platform` without blocking task updates
