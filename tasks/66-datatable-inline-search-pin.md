---
id: "66"
title: "DataTable inline search with row pinning"
status: pending
group: vendors
phase: vendors
priority: medium
type: feature
tags: [shared-ui, datatable, filtering, ux]
effort: large
created: 2025-03-25
---

## Purpose

Replace the sidebar vendor filter dropdown with an inline search-and-pin interaction directly in the DataTable. Users search via a text input above the table, find vendors of interest, and pin them. Pinned rows persist at the top while the user continues searching. This is more discoverable and flexible than the current sidebar multi-select filter.

## Design decisions

- **Search input**: Built into DataTable using TanStack Table's `getFilteredRowModel()` with a global filter. Real-time client-side filtering across all visible columns as the user types.
- **Pin icon**: Small pin/thumbtack icon on the left side of each row. Click to pin; click again to unpin.
- **Pinned rows**: Appear at the top of the table above a subtle divider, always visible regardless of search text or sort order.
- **Sorting**: Applies within the pinned group and within the unpinned group independently. Pinned rows always stay above unpinned.
- **Search scope**: Search/filter only applies to unpinned rows. Pinned rows are always shown.
- **Persistence**: Session-only (React state). Pins do not survive page reload.
- **Sidebar simplification**: Remove the VendorFilters dropdown from the sidebar once this is in place. The sidebar retains the Vendors/Spending tab switcher.

## Approach

### shared-ui (`data-table.tsx`)

1. Add `globalFilter` state and `getFilteredRowModel()` to `useReactTable` config.
2. Render a search `<Input>` above the table (next to the Download CSV button) with a search icon and clear button.
3. Add optional `enablePinning` prop. When enabled:
   - Track `pinnedRowIds` in component state (Set of row IDs).
   - Render a pin icon column as the first column.
   - Split `table.getRowModel().rows` into pinned and unpinned groups.
   - Render pinned rows first, followed by a visual divider row, then unpinned (filtered) rows.
4. Export any new types needed.

### vendors (`VendorList.tsx`, `App.tsx`)

1. Pass `enablePinning` to DataTable.
2. Remove `VendorFilters` component usage from `App.tsx` sidebar.
3. Remove the `filteredVendors` logic — pass full `vendors` array to `VendorList` and let DataTable handle filtering.
4. Clean up or delete `VendorFilters.tsx` if no longer needed.

## Acceptance criteria

- [ ] Text input above table filters rows in real-time across all columns.
- [ ] Pin icon on each row toggles pin state.
- [ ] Pinned rows appear at top, separated by a divider.
- [ ] Search only filters unpinned rows; pinned rows always visible.
- [ ] Sorting works independently within pinned and unpinned groups.
- [ ] Sidebar vendor filter dropdown is removed.
- [ ] No regressions on spend table (it uses DataTable without pinning).
