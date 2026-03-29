---
id: "48"
title: "Finish vendor API integrations plan and implement"
status: in-progress
group: vendors
phase: vendors
priority: high
type: feature
tags: [vendors, integrations, billing, spend, vendor-data]
effort: large
---

# Finish vendor API integrations plan and implement

## Context

An in-progress plan exists at:

`/Users/michaelmader_1/.cursor/plans/vendor_api_integrations_145fa5d6.plan.md`

The plan covers adding direct spend integrations for five vendors: GCP, Vercel, OpenAI, Cursor, and Slack. Research is complete. Three vendors (GCP, Vercel, OpenAI) have direct spend APIs. Two (Cursor, Slack) lack spend endpoints.

## Decisions

- **Cursor / Slack spend source:** Seat-derived spend (seats x unit price from admin APIs). Email invoice parsing deferred to a future task.

## Remaining work

1. Implement Tier 1 integrations (OpenAI, Vercel, GCP) -- direct spend APIs
2. Implement Tier 2 integrations (Cursor, Slack) -- seat-derived spend
3. Refactor app.py to fetcher registry pattern
4. Add Secret Manager secrets and Cloud Run env bindings
5. Update frontend VENDORS array, architecture docs, and .env.example
