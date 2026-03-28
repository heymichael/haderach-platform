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

The `PATCH /vendors/{vendor_id}` endpoint in the agent service currently only verifies that the caller is an authenticated user (`get_verified_user`). It does not check whether the caller has permission for the specific vendor being modified. Any authenticated user can edit any vendor's details.

Spend access control (Task 65) gates which vendors' spend data a user can see, but vendor CRUD operations are not similarly gated.

## What needs to happen

### 1. Endpoint architecture review

A lot has changed since the vendor CRUD endpoints were originally built (access control model, caller context, effective vendor sets). Before adding permission gates, review and decide on the right endpoint architecture for vendor CRUD operations going forward. This may include restructuring routes, standardizing error responses, or consolidating middleware.

### 2. Permission-gate vendor CRUD endpoints

- Gate `PATCH /vendors/{vendor_id}` on the caller's effective vendor set (resolved from `allowed_departments`, `allowed_vendor_ids`, `denied_vendor_ids` on the user doc)
- Gate `DELETE /vendors/{vendor_id}` with the same check
- `finance_admin` users bypass the check (full access)
- Return 403 if the caller does not have permission for the target vendor
- Audit any other vendor mutation endpoints (e.g., `set_vendor_hidden`) for the same gap

### 3. UI controls

- Ensure the vendors app UI disables or hides edit/delete controls for vendors outside the caller's effective set

## Reference

- Endpoints: `agent/service/app.py` — `PATCH /vendors/{vendor_id}`, `DELETE /vendors/{vendor_id}`
- Effective vendor resolution: `agent/service/firestore_client.py` — `compute_effective_vendor_ids`
- Caller context builder: `agent/service/tools.py` — `_build_caller_context`
