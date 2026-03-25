---
id: "58"
title: "Move vendor sync job out of agent repo"
status: pending
group: vendors
phase: vendors
priority: medium
type: refactor
tags: [sync, cloud-scheduler, agent, vendors, platform, infra]
dependencies: ["56"]
effort: small
created: 2026-03-25
---

## Purpose

The Bill.com vendor sync job (`service/sync_billcom.py`) currently lives in the agent repo. The agent service is intended to be a shared backend consumed by multiple apps (vendors, card, stocks). Vendor-specific data pipeline jobs should not live there.

## Context

The sync job was built in the agent repo (task 56, Phase 2) because it shares the same Firestore client and Bill.com credentials. This was expedient for the initial build, but as the agent becomes multi-app, vendor-specific jobs need to move.

## Decision needed

Where should the sync job live?

- **vendors repo** — it's vendor-specific data infrastructure, and the vendors app is the primary consumer of the Firestore `vendors` collection. Natural fit if each app owns its own data pipelines.
- **haderach-platform repo** — if multiple apps end up with sync jobs (vendor sync, stock data sync, etc.), centralizing pipelines in platform keeps orchestration in one place.

## When to do this

The natural inflection point is when setting up Cloud Scheduler for the nightly run. A Cloud Run Job doesn't need to be in the same repo as the API service it feeds — it just needs Firestore and Bill.com credentials.

## What moves

- `agent/service/sync_billcom.py` → new home
- Bill.com credential access (already in Secret Manager)
- Firestore client setup (trivial to replicate)
- Cloud Run Job + Cloud Scheduler config (not yet created)
