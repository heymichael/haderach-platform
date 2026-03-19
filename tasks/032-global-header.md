---
id: "032"
title: "Add global header across all apps with logo and home navigation"
status: pending
group: platform
phase: platform
priority: high
type: feature
tags: [navigation, cross-app, ux]
effort: large
created: 2026-03-18
---

## Purpose / Objective

Add a persistent global header that appears across all apps and the homepage, providing consistent visual context and navigation. Move the logo into the header to free up the homepage for actual content.

## Current State

- The homepage (`hosting/public/index.html`) shows a large centered logo with nav links above it -- the logo dominates the page with no room for content.
- Each app (card, stocks) has its own independent layout with no shared navigation chrome.
- There is no way to navigate back to the homepage or between apps once inside an app.

## Approach / Acceptance Criteria

- [ ] Global header component with the Haderach logo (compact/scaled-down) that links to the homepage (`/`).
- [ ] Header includes navigation links to each app (`/card/`, `/stocks/`).
- [ ] Header appears on the homepage and within each app, providing consistent cross-app context.
- [ ] Active app is visually indicated in the header (e.g., highlighted link).
- [ ] Homepage is updated to remove the large centered logo (now in the header) and use the freed space for content.
- [ ] Header design is minimal and consistent with the existing dark theme (`#0b0f1a`).
- [ ] Determine delivery approach: shared snippet injected at platform level vs shared component/package consumed by each app.

## Design Inspiration

- https://madammadam.es/
- https://tometlucas.com/
- https://avinastiftung.ch/
- https://kroton.be/
- https://realdealpainting.net/
- https://www.axongarside.com/blog/best-b2b-website-design-examples
