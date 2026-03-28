---
id: "81"
title: "Remove left sidebar nav, move to top nav buttons and collapsible app selector"
status: pending
group: vendors
phase: vendors
priority: high
type: improvement
tags: [ui, navigation, vendors, shared-ui]
effort: medium
created: 2026-03-28
---

## Purpose

The vendors app currently uses a left sidebar for view navigation (Vendors / Spending) and places spend controls in the main content area. The sidebar takes up horizontal space and is redundant now that spend controls have moved above the graph. Replace the sidebar navigation with top-level nav buttons and move the app selector (GlobalNav) into a collapsible left rail.

## Current state

- Left sidebar contains: Vendors / Spending view toggles (SidebarMenu), SidebarRail.
- GlobalNav sits above the sidebar as a full-width top bar with app links.
- Spend controls (department, vendor, date filters) already live above the graph in the main content area.

## Approach

1. Remove the `Sidebar`, `SidebarContent`, `SidebarGroup`, `SidebarMenu`, `SidebarRail`, `SidebarProvider` from the vendors layout.
2. Add Vendors / Spending toggle buttons in the header bar (next to the page title area), replacing the sidebar menu items.
3. Move the app selector (currently in GlobalNav's top bar) into a collapsible left nav rail that can be toggled open/closed.
4. Evaluate whether these changes should be made in shared-ui (GlobalNav) or locally in vendors first.

## Acceptance criteria

- [ ] No left sidebar for view navigation — Vendors/Spending toggle is in the top header.
- [ ] App selector lives in a collapsible left rail.
- [ ] Spend toolbar, chart, and table continue to work as before.
- [ ] Chat panel continues to work on the right side.
- [ ] Layout is responsive and doesn't break on narrow viewports.
