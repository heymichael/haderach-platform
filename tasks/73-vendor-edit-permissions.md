---
id: "73"
title: "Restrict vendor detail editing to users with vendor-level permissions"
status: pending
group: vendors
phase: vendors
priority: high
type: feature
tags: [vendors, permissions, access-control]
dependencies: []
effort: medium
created: 2026-03-27
---

## Context

Currently, users may be able to edit vendor details without having the appropriate permissions for that specific vendor. Editing should be gated so that only users with permissions for a given vendor can change its details.

## What needs to happen

- Enforce vendor-level permission checks before allowing edits to vendor details
- Ensure the UI disables or hides edit controls for users without the required permissions
- Validate permissions server-side so the restriction can't be bypassed from the client
