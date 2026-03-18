---
id: "007"
title: "Enable analytics export to BigQuery"
status: completed
group: card
phase: card
priority: high
type: feature
tags: [analytics, bigquery, gcp]
created: 2026-03-13
---

# Enable analytics export to BigQuery

## Purpose

Analytics events are instrumented in-app but only visible in Firebase/GA4 consoles today. Enable the Firebase → BigQuery export so raw event data is queryable, unthresholded, and available for custom dashboards and downstream analysis. Export is not retroactive, so enabling early is critical.

## Approach

1. Enable BigQuery export in Firebase Console (Project Settings → Integrations) — do this first since export is not retroactive.
2. Verify the auto-created `analytics_<project_id>` dataset in BigQuery; configure access controls and confirm billing project.
3. Register custom event parameters as GA4 custom dimensions (GA4 Admin → Custom definitions) so they appear in console reports.
4. Create initial validation query against `events_*` tables to confirm data flow.
5. (Optional) Set up a Looker Studio dashboard or scheduled query for key metrics (card_exported, card_conversion, sign_in_denied).
6. Update `docs/architecture.md` to remove the "if export is enabled" qualifier and document the BigQuery dataset, access, and any dashboard links.
