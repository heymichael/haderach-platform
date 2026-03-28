---
id: "57"
title: "Add Haderach favicon across all apps"
status: pending
group: platform
phase: platform
priority: low
type: chore
tags: [ui, branding, admin-revamp, experiment]
effort: small
created: 2026-03-24
---

## Purpose

No favicon is configured — every app tab shows the browser default icon. The Haderach logo should appear in the browser tab globally, regardless of which app the user is on.

## Approach

1. Optimize the existing logo SVG at `haderach-home/public/assets/landing/logo.svg` (strip Illustrator metadata to reduce from ~175 KB) and place it at `haderach-home/public/favicon.svg` so Vite copies it to the root of the build output
2. The `home` app extracts at the root of `hosting/public/` during deploy, so `/favicon.svg` will be served globally without per-app duplication
3. Add `<link rel="icon" type="image/svg+xml" href="/favicon.svg" />` to `index.html` in each app repo (vendors, stocks, card, haderach-home) — browsers auto-discover `.ico` but require an explicit link tag for SVG favicons
