---
id: "15"
title: "Migrate private docs delivery to Cloud Run + IAP"
status: cancelled
group: platform
phase: platform
priority: low
type: feature
tags: [docs, cloud-run, iap, security]
created: 2026-03-03
---

# Migrate private docs delivery to Cloud Run + IAP

## Purpose

Replace the temporary static-hosted docs approach with server-enforced private access so docs are no longer accessible via direct static URLs.

## Approach

Implement per-app docs services behind Cloud Run + IAP, route `/app/docs/**` to the docs service before `/app/**`, preserve the tabbed docs shell UX, and verify only authorized users can load underlying tab documents.
