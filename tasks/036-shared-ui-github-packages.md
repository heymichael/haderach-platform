---
id: 36
title: Publish @haderach/shared-ui to GitHub Packages
group: home
phase: home
status: pending
priority: medium
depends_on: []
---

# Publish @haderach/shared-ui to GitHub Packages

## Context

Stocks and card depend on `@haderach/shared-ui` via `file:../haderach-home/packages/shared-ui`. This works locally but breaks CI because the home repo isn't checked out alongside. A cross-repo checkout workaround is in place but is fragile. Publishing the package to GitHub Packages (npm registry) is the proper fix.

## Acceptance criteria

- [ ] Add a build step to `packages/shared-ui` that compiles TS to JS and emits `.d.ts` declarations
- [ ] Add a publish workflow to `haderach-home` that publishes `@haderach/shared-ui` to `npm.pkg.github.com` on push to `main`
- [ ] Stocks and card switch dependency from `file:` to `@haderach/shared-ui` semver range
- [ ] Add `.npmrc` to stocks and card pointing `@haderach` scope at GitHub Packages
- [ ] CI in stocks and card can install `@haderach/shared-ui` from the registry without cross-repo checkout
- [ ] Local dev still uses `file:` override or workspace link for hot-reload

## Notes

- Once this is done, remove the cross-repo checkout workaround from stocks and card CI workflows
- Consider whether `GITHUB_TOKEN` with `packages:read` is sufficient or if a PAT is needed
