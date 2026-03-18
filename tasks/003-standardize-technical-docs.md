---
id: "003"
title: "Standardize technical documentation"
status: pending
group: card
phase: card
priority: low
type: docs
tags: [docs, api-reference]
created: 2026-03-12
---

# Standardize technical documentation

## Purpose

Define a standard for technical documentation so the card app (and template) have consistent, engineer-friendly API docs. Today `documentation.html` uses a good content format (API reference layout, function signatures, file-based organization, tags, props/state tables) but is hand-maintained standalone HTML with no search, sidebar, or deep links. Standardize so docs either are generated from source (TypeDoc/JSDoc) or are integrated into a docs framework with search, sidebar, and deep links.

## Approach

- **Content standard (keep):** API reference layout (Field | Type | Description), function signatures with typed params and short descriptions, file-based sections, tags (interface, type alias, function component), props/state tables — align with TypeDoc/JSDoc/Storybook-style expectations.
- **Delivery standard (improve):** Decide and document: (a) generate from source (e.g. TypeDoc/JSDoc) so API docs stay in sync, or (b) keep hand-written but integrate into a docs framework (Docusaurus, MkDocs, Storybook, or existing docs shell) with search, sidebar, and deep links to symbols.
- Document the standard in learnings or architecture; apply to `documentation.html` / card app; propose template change for the canonical app template.
