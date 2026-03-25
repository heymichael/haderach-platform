---
id: "54"
title: "Add codebase stats tracking script"
status: pending
group: platform
phase: platform
priority: low
type: improvement
tags: [tooling, metrics, scc]
effort: small
created: 2026-03-23
---

## Purpose

Provide a quick way to see total lines of code across all app repos and the platform repo. Useful for tracking codebase growth over time and measuring the impact of refactoring work (e.g., deduplication).

## Approach

1. Add a script (e.g. `scripts/codebase-stats.sh`) that runs `scc` across all repos and outputs a summary table.
2. Exclude `node_modules`, `dist`, `.cursor`, `.github` directories.
3. Split out SVG lines separately (logo files inflate the count).
4. Optionally log results to a file (`stats/codebase-stats.log`) with timestamps for historical tracking.

## Dependencies

- `scc` must be installed locally (`brew install scc`).
