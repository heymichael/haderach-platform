---
id: "85"
title: "Rename admin-finance to admin-vendors"
status: completed
group: platform
phase: platform
priority: medium
type: chore
tags: [admin-revamp, rename, infra]
dependencies: []
effort: medium
created: 2026-03-29
---

## Context

The admin apps should be named after the objects being permissioned, not the role doing the granting. `admin-finance` manages vendor-level permissions and spend data, so `admin-vendors` is a more accurate name. This aligns with the mental model: `admin-system` grants system rights, `admin-vendors` grants vendor rights.

The `finance_admin` role name stays unchanged — renaming a role stored in Firestore user docs is a separate, larger migration and not needed for this change.

## What needs to happen

### admin-finance repo (~9 files)
- `package.json` / `package-lock.json` — package name
- `vite.config.ts` — base path and outDir (`/admin/finance/` to `/admin/vendors/`)
- `src/auth/AuthGate.tsx` — APP_PATH
- `src/auth/accessPolicy.ts` — APP_ID (`finance_administration` to `vendor_administration`)
- `.github/workflows/publish-artifact.yml` — GCS paths
- `scripts/generate-manifest.mjs` — app_id
- `README.md`, `docs/architecture.md`
- `.cursor/rules/repo-hygiene.mdc`

### haderach-platform (~12 files)
- `firebase.json` — hosting rewrites
- `.github/workflows/deploy.yml`, `redeploy-all.yml`, `batch-deploy.yml`
- `scripts/latest-artifact-sha.sh`
- `.cursor/rules/local-dev-testing.mdc`
- `infra/workload-identity.tf` — WIF principal (GitHub repo name)
- `infra/service-accounts.tf`, `infra/gcs.tf` — resource names/comments
- `docs/architecture.md`
- ~10 task files (prose references)

### haderach-home (1 file)
- `packages/shared-ui/src/auth/app-catalog.ts` — path and label

### Infrastructure
- Rename the GitHub repo (`gh repo rename`)
- Rename the local directory
- Run `terraform apply` to update WIF binding
- Deploy under the new app ID to populate GCS artifacts

### Coordination
The GitHub repo rename, Terraform apply, and first deploy under the new name need to happen together to avoid breaking CI.

## Execution order (admin revamp)

1. **Task 85** — Rename admin-finance to admin-vendors (this task)
2. **Task 67 Part 1** — GlobalNav avatar dropdown
3. **Task 80 (Users + Roles)** — Add react-router-dom, extract UsersPage and RolesPage
4. **Task 77** — Dynamic app permissioning backend
5. **Task 80 (Apps page)** — Add AppsPage route once task 77 backend is ready
6. **Task 67 Part 2** — Settings hub SPA at `/admin/`

## Implementation plan

`/Users/michaelmader_1/.cursor/plans/rename_admin-finance_to_admin-vendors_082f0796.plan.md`

## Notes
- The `finance_admin` role name is NOT changed — it stays in Firestore and code as-is
- All file edits are mechanical find-and-replace, no logic changes
- Cross-repo status rule and other shared cursor rules need `admin-finance` updated to `admin-vendors` in their repo lists
