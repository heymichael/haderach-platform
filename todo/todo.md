Todo: haderach (repo / infrastructure)

Open items

1. [Med] Extend automatic testing coverage to all apps
2. [Med] Add PR process/template and requirements process/template
3. [Low] Migrate private docs delivery to Cloud Run + IAP (replace temporary static hosting)
4. [Low] Improve deploy-time E2E test visibility in GitHub Actions
5. [Low] Enforce Required PR Gate via branch protection on main

Completed items

- [2026-03-05] Document shared docs-shell architecture after haderach rollout (no PR)
- [2026-03-03] Implement tabbed docs generation and requirements catalog workflow (PR #6)
- [2026-03-03] Generate rendered todo docs per app (no PR)
- [2026-03-03] Document local GitHub PR tooling setup (git + gh + auth + access checks) (PR #4)
- [2026-03-03] Improve PR conventions rule for commit-to-PR approval workflow (PR #4)
- [2026-03-03] Point haderach.ai DNS to Firebase Hosting (no PR)
- [2026-03-03] Add global robots.txt to block crawling (no PR)
- [2026-03-02] Implement app + docs auth (Google, per-app rules, single sign-on) (no PR)
- [2026-03-02] Document infrastructure (hosting, directory structure, CI pipeline, and related) (no PR)

1. Extend automatic testing coverage to all apps

Purpose: Extend automated testing beyond the card app so each app has appropriate app-specific tests while maintaining a single, consistent testing framework and workflow across the monorepo.

Approach: Define and adopt a unified testing framework (commands, structure, reporting, CI integration, and quality gates) used consistently across all apps. Implement only app-specific test suites per app under that shared framework, so each app tests its own behavior while tooling, execution flow, and reporting remain standardized.

2. Add PR process/template and requirements process/template

Purpose: Establish a consistent, repeatable process for pull requests and requirements capture so contributors follow the same standards and reviewers have predictable context.

Approach: Define a lightweight PR process doc and PR template covering scope, validation, rollout/rollback notes, and review expectations. In parallel, define a requirements process doc and requirements template that capture objective, constraints, acceptance criteria, dependencies, and release impact. Link both from `README.md` and `docs/architecture.md` once approved.

3. Migrate private docs delivery to Cloud Run + IAP (replace temporary static hosting)

Purpose: Replace the temporary static-hosted docs approach with server-enforced private access so docs are no longer accessible via direct static URLs.

Approach: Implement per-app docs services behind Cloud Run + IAP, route /app/docs/** to the docs service before /app/**, preserve the tabbed docs shell UX, and verify only authorized users can load underlying tab documents.

4. Improve deploy-time E2E test visibility in GitHub Actions

Purpose: Reduce uncertainty during long deploys by making it clear where E2E execution is in progress and whether tests are actively advancing.

Approach: Update CI test reporting to stream per-test progress in Action logs (for example using Playwright line reporter alongside HTML), define expected duration thresholds/alerts for the deploy test step, and add lightweight runbook guidance for when to cancel/retry stalled runs.

5. Enforce Required PR Gate via branch protection on main

Purpose: Ensure deploy-smoke and required quality checks are true merge blockers by enforcing the Required PR Gate status check at the branch level.

Approach: After this PR merges and the new workflow has run at least once on main, configure GitHub branch protection for main to require Required PR Gate before merge. Then verify with a test PR that merge is blocked on failure and allowed on success.
