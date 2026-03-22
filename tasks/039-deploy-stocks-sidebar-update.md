---
id: 39
title: Run production deploy for stocks sidebar layout update
group: stocks
phase: stocks
status: done
priority: urgent
depends_on: []
---

## Context

Stocks app PR #12 (feat/sidebar-layout) has been merged, adding the new sidebar layout with nav views and teal-green primary color. The artifact publish workflow should run automatically on merge, but the platform production deploy workflow needs to be triggered manually to promote the new artifact to production.

## Steps

1. Confirm the stocks `app-publish-artifact` workflow completed successfully after PR #12 merge
2. Run the platform deploy workflow targeting the stocks app with the latest artifact version
3. Verify the deployed app at production URL — sidebar layout, nav switching, and teal-green button color should all be visible
