---
id: "035"
title: "Bridge card app design tokens into Tailwind theme"
status: done
group: card
phase: card
priority: low
type: enhancement
tags: [tailwind, design-tokens, card]
effort: medium
---

# Bridge card app design tokens into Tailwind theme

## Context

The card app has its own color system in `src/theme/colors.css` using custom CSS variables (`--color-surface-app-bg`, `--color-accent-interactive-primary`, etc.) with a warm cream/gold palette. These work alongside a minimal Tailwind `@theme` block that was added to support the shared GlobalNav and dropdown components.

## Goal

Map card's existing custom CSS variables into Tailwind's `@theme` so Tailwind utility classes can be used throughout the card app. Update `check-color-tokens.mjs` linter to understand the new token references.

## Tasks

- [x] Add all card design tokens from `colors.css` to the `@theme` block in `index.css`
- [x] Evaluate incremental migration of `App.css` styles to Tailwind utilities — deferred, `App.css` already uses `var()` tokens throughout; migration to utility classes is optional and can be done incrementally
- [x] Update `check-color-tokens.mjs` to handle Tailwind token references
- [x] Verify card renders correctly after changes

## Notes

- Not urgent — the card works fine with its current CSS variable approach
- Main benefit is enabling incremental migration to Tailwind utility classes
- Extracted from parent plan `tailwind_shadcn_home_repo` Phase 4
