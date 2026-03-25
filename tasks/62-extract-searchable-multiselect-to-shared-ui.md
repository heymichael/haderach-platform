---
id: "62"
title: "Extract SearchableMultiSelect component to shared-ui"
status: pending
group: platform
phase: platform
priority: low
type: feature
tags: [shared-ui, component, multiselect, search, radix, vendors]
dependencies: []
---

## Context

The vendors app now has a local `VendorFilters` component that implements a searchable multi-select pattern using `@radix-ui/react-popover`, `Input`, `Button`, and `lucide-react` `Check`. It supports:

- Popover trigger with summary label
- Auto-focused search input that filters the list in real time
- Scrollable checkbox list with multi-select
- "Select all" / "Select matches" / "Clear" actions

This pattern is generic enough to be reused across other apps (stocks, card) wherever a filterable multi-select is needed.

## Acceptance criteria

- [ ] Create a `SearchableMultiSelect` (or similar) component in `@haderach/shared-ui`
- [ ] Props: `options: { id: string; label: string }[]`, `selected: string[]`, `onChange: (ids: string[]) => void`, `placeholder?: string`, `label?: string`
- [ ] Supports search filtering, select all / clear, scrollable list
- [ ] Refactor `vendors/src/VendorFilters.tsx` to use the shared component
- [ ] Verify no regressions in the vendors app vendor selector

## Reference

- Current local implementation: `vendors/src/VendorFilters.tsx`
- Shared-ui package: `haderach-home/packages/shared-ui/`
