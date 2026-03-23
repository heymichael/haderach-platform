---
id: "017"
title: "Enforce Required PR Gate via branch protection on main"
status: cancelled
group: platform
phase: platform
priority: low
type: chore
tags: [ci, github]
created: 2026-03-03
---

# Enforce Required PR Gate via branch protection on main

## Purpose

Ensure deploy-smoke and required quality checks are true merge blockers by enforcing the Required PR Gate status check at the branch level.

## Approach

After this PR merges and the new workflow has run at least once on main, configure GitHub branch protection for main to require Required PR Gate before merge. Then verify with a test PR that merge is blocked on failure and allowed on success.
