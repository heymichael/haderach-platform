---
id: "62"
title: "Refactor VendorFilters to use shared MultiSelect component"
status: cancelled
group: vendors
phase: vendors
priority: high
type: feature
tags: [shared-ui, component, multiselect, search, vendors, vendor-components]
dependencies: []
---

## Context

The vendors app has a local `VendorFilters` component (`vendors/src/VendorFilters.tsx`) that implements a searchable multi-select using `@radix-ui/react-popover`, `Input`, `Button`, and `lucide-react` `Check`. A shared `MultiSelect` component now exists in `@haderach/shared-ui` (`haderach-home/packages/shared-ui/src/components/ui/multi-select.tsx`) with equivalent and improved functionality:

- Search filtering with auto-focus
- Select all / Clear actions (shown simultaneously)
- Scrollable checkbox list with selected items sorted to the top
- Custom item rendering via `renderItem` prop

## Completed

- [x] Created `MultiSelect` component in `@haderach/shared-ui`
- [x] Props: `items: { id, label }[]`, `selectedIds: string[]`, `onSelectionChange`, `placeholder`, `searchPlaceholder`, `renderItem`, `className`
- [x] Supports search filtering, select all / clear, scrollable list, selected-first sorting with separator

## Remaining

- [ ] Refactor `vendors/src/VendorFilters.tsx` to use `MultiSelect` from `@haderach/shared-ui`
- [ ] Remove `@radix-ui/react-popover` dependency from vendors if no longer used elsewhere
- [ ] Verify no regressions in the vendors app vendor selector

## Reference

- Shared component: `haderach-home/packages/shared-ui/src/components/ui/multi-select.tsx`
- Local implementation to replace: `vendors/src/VendorFilters.tsx`
