---
id: "9"
title: "Manage GA4 custom dimensions programmatically"
status: cancelled
group: card
phase: card
priority: low
type: improvement
tags: [analytics, ga4, infra-as-code]
created: 2026-03-13
---

# Manage GA4 custom dimensions programmatically

## Purpose

Custom dimension registrations in GA4 are effectively permanent (archive doesn't free slots, only Google Support can truly delete). Managing them via the Admin API instead of the UI ensures registrations are version-controlled, reviewable, and deliberate — reducing the risk of wasting slots from the 50-dimension limit.

## Approach

1. Create a script that registers custom dimensions via the GA4 Admin API (`analyticsadmin.googleapis.com/v1beta/properties/{id}/customDimensions`).
2. Define the dimension list (parameter name, display name, scope, description) in a config file checked into the repo.
3. Make the script idempotent — list existing dimensions first, only create missing ones.
4. Require `gcloud` auth with `analytics.edit` scope and Editor role on the GA4 property.
5. Optionally add a CI dry-run step that diffs the config against live dimensions and warns on unregistered parameters.
