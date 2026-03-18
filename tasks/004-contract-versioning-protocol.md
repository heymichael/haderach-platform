---
id: "004"
title: "Add contract versioning protocol docs alignment with platform"
status: pending
group: card
phase: card
priority: low
type: docs
tags: [contracts, platform]
created: 2026-03-12
---

# Add contract versioning protocol docs alignment with platform

## Purpose

Document how app manifest contract versions evolve over time so app/platform behavior is explicit when moving beyond `platform_contract_version: "v1"`, while deferring implementation details until after the first successful deploy.

## Approach

After first deploy, update platform `docs/architecture.md` with a Contract Versioning Protocol section (breaking vs non-breaking changes, bump process, compatibility guarantees, and deprecation window), then add a concise pointer in this app repo's `docs/architecture.md`/`README.md` to that platform-owned protocol as the source of truth.
