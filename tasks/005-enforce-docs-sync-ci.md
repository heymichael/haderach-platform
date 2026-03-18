---
id: "005"
title: "Enforce docs source-to-served sync in CI"
status: cancelled
group: card
phase: card
priority: low
type: chore
tags: [ci, docs]
created: 2026-03-12
---

# Enforce docs source-to-served sync in CI

## Purpose

Prevent drift between `docs/` and `hosting/public/docs/` by making the existing generate-and-sync workflow a required CI gate.

## Approach

Add CI steps that run `python3 scripts/generate_docs_pages.py` and `bash scripts/sync_docs.sh`, then fail if `git diff --exit-code` is non-empty so PRs cannot merge with stale served docs output.
