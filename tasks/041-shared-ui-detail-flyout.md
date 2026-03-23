---
id: 41
title: Move detail fly-out panel to shared-ui
group: home
phase: home
status: cancelled
priority: low
depends_on: []
---

## Summary

Extract the vendor detail fly-out (Sheet-based slide-over panel) from the vendors app into a reusable `DetailPanel` component in `@haderach/shared-ui`.

## Context

The vendors app uses a Sheet-based slide-over to show vendor detail when clicking a table row. This pattern (table row click → slide-over with structured detail sections) is generic enough to be useful across other apps.

## Requirements

- Create a `DetailPanel` component in shared-ui that wraps Sheet with:
  - Configurable title, subtitle, and status badge
  - `DetailSection` sub-component for grouped label/value rows
  - `DetailRow` sub-component for individual label/value pairs with optional link support
  - Configurable animation speed (the current Sheet animation is too fast relative to the sidebar)
- Migrate the vendors app `VendorDetail.tsx` to use the shared component
- Ensure animation duration can be customized (currently blocked by Tailwind class override issues)

## Notes

- Low priority — the app-local implementation works fine for now
- Animation speed issue may require changes to the Sheet component's base classes in shared-ui
