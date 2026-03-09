# haderach-platform

Platform control plane for `haderach.ai`.

This repository owns shared hosting/routing/deploy orchestration and cross-app smoke checks.
Application implementation, app CI, and app-local tests live in separate app repositories (for example `card_app`, `quote_app`, and future client app repos).

## What this repo is responsible for

- Shared host and routing topology for `haderach.ai`.
- Promotion of app-published artifacts into deployable platform state.
- Environment deploy orchestration.
- Platform-level smoke checks across app routes.
- Security/indexing defaults.

## What this repo is not responsible for

- App business logic.
- Building app source from app repos.
- App unit/integration test suites.

## Repository layout (initial)

- `hosting/public/` - platform-hosted static root content.
- `firebase.json` - hosting baseline and security/indexing defaults.
- `.github/workflows/deploy.yml` - safe starter deploy workflow (manual, placeholder deploy).
- `docs/architecture.md` - ownership boundaries, release flow, routing model.
- `docs/app-registry.example.json` - app registry contract template.
- `docs/index.html` + `docs/shared/` - reusable docs shell for `/docs` surfaces.
- `scripts/` - docs generation and hosting sync helpers for local parity.

```text
haderach-platform/
├── .cursor/
│   └── rules/
│       ├── architecture-pointer.mdc
│       ├── branch-safety-reminder.mdc
│       ├── pr-conventions.mdc
│       ├── repo-hygiene.mdc
│       └── todo-conventions.mdc
├── .github/
│   └── workflows/
│       └── deploy.yml
├── docs/
│   ├── index.html
│   ├── architecture.md
│   ├── architecture.html
│   ├── app-registry.example.json
│   ├── priorities/
│   │   └── index.html
│   ├── requirements/
│   │   ├── catalog.json
│   │   └── projects/
│   │       └── requirements-project.template.html
│   ├── test-status/
│   │   ├── catalog.json
│   │   ├── checks/
│   │   │   ├── deploy-smoke-artifact-checks.html
│   │   │   ├── deploy-smoke-contract-checks.html
│   │   │   ├── nightly-e2e-regression-artifact-checks.html
│   │   │   ├── nightly-e2e-regression-contract-checks.html
│   │   │   ├── prod-monitor-artifact-checks.html
│   │   │   └── prod-monitor-contract-checks.html
│   │   ├── reports/
│   │       ├── deploy-smoke.html
│   │       ├── nightly-e2e-regression.html
│   │       └── prod-monitor.html
│   │   └── summaries/
│   │       ├── deploy-smoke-summary.json
│   │       ├── nightly-e2e-regression-summary.json
│   │       └── prod-monitor-summary.json
│   ├── testing/
│   │   ├── catalog.json
│   │   ├── test-lineup.html
│   │   └── testing-infrastructure.html
│   └── shared/
│       ├── docs-shell.css
│       ├── docs-shell-page.template.html
│       └── docs-shell.js
├── hosting/
│   └── public/
│       ├── assets/
│       │   └── landing/
│       │       └── logo.svg
│       ├── index.html
│       └── robots.txt
├── scripts/
│   ├── generate_docs_pages.py
│   ├── requirements-docs.txt
│   └── sync_docs.sh
├── todo/
│   └── todo.md
├── .firebaserc
├── .gitignore
├── firebase.json
└── README.md
```

## Local development

Prerequisites:

- Node.js + npm
- Firebase CLI
- Python 3 (for docs generation)

Suggested commands:

```bash
npm --version
python3 --version
firebase --version
python3 -m pip install -r scripts/requirements-docs.txt
python3 scripts/generate_docs_pages.py
bash scripts/sync_docs.sh
firebase emulators:start --only hosting --project haderach-ai --config firebase.json
```

## App repo integration model

Each app repo publishes immutable artifacts + metadata manifest.
Platform reads that manifest via the app registry contract and promotes a version per environment.

## Shared docs shell

The docs shell assets in `docs/shared/` are the canonical UI for all docs pages:

- Platform docs: `haderach.ai/docs/` from `docs/index.html`.
- App docs: `haderach.ai/<app>/docs/` in each app repo, reusing the same shell CSS/JS and template shape.

Use `docs/shared/docs-shell-page.template.html` as the copy baseline for app repos, and set each app's `baseDocsPath` (for example `/card/docs`) so tabs resolve correctly.

Canonical files to copy into each app repo:

- `scripts/generate_docs_pages.py`
- `scripts/sync_docs.sh`
- `scripts/requirements-docs.txt`

- `docs/index.html`
- `docs/shared/docs-shell.css`
- `docs/shared/docs-shell.js`
- `docs/shared/docs-shell-page.template.html`

Template replacement values per app:

- `__APP_NAME__` (for example `Card`)
- `__DOCS_BASE_PATH__` (for example `/card/docs`)

For strict tab parity, each app docs root should also include:

- `<base>/test-status/catalog.json`
- `<base>/priorities/index.html`
- `<base>/requirements/catalog.json`
- `<base>/testing/catalog.json`
- `<base>/architecture.md` (source)
- `<base>/architecture.html` (rendered target)

Architecture tab standard: `baseDocsPath + "/architecture.html"` for both platform and app docs shells.

Requirements authoring/deploy contract (same pattern as priorities):

- Canonical authoring source: `docs/requirements/projects/*.html`
- Canonical index/catalog source: `docs/requirements/catalog.json`
- Served deploy copy after sync: `hosting/public/docs/requirements/projects/*.html` and `hosting/public/docs/requirements/catalog.json`

Canonical requirements template:

- `docs/requirements/projects/requirements-project.template.html`

## Template Bootstrap Checklist

When cloning this structure for a new app repository:

1. Update app identity and routes:
   - Set docs base path for the app (for example `/card/docs`) in `docs/index.html`.
   - Update app display labels in docs pages/templates where appropriate.
2. Normalize script identity:
   - In `scripts/generate_docs_pages.py`, set `APP_DISPLAY_NAME` to your app name.
3. Seed content sources:
   - Add or update `docs/requirements/catalog.json` and project docs in `docs/requirements/projects/`.
   - Add or update `docs/testing/catalog.json` + testing pages.
   - Add or update `docs/test-status/catalog.json` + reports/checks/summaries placeholders.
4. Generate and sync:
   - `python3 scripts/generate_docs_pages.py`
   - `bash scripts/sync_docs.sh`
5. Verify shell behavior locally:
   - Load docs root and each tab.
   - Verify list/detail/back flows for requirements, testing, and test-status.
   - Verify deep links (`?tab=...`, item params) and invalid-item fallbacks.
6. Verify security/indexing defaults:
   - Confirm `noindex, nofollow, noarchive` policy remains in meta + headers.

See:

- `docs/architecture.md`
- `docs/app-registry.example.json`

## Promotion/deploy model options

### Option A: Auto-promote

- After app artifact publish, policy auto-selects latest passing version for staging.
- Production promotion remains gated (manual approval recommended).

### Option B: PR-promote (recommended starter)

- Promotion change is submitted as a platform PR (manifest/version bump).
- Review + merge drives deployment workflow.
- Clear audit trail and rollback simplicity.

## Migration plan for first app onboarding (short)

1. Define app registry entry:
   - `app_id`, `route_prefix`, artifact manifest URI, docs route.
2. Implement app repo artifact publish + metadata contract (`v1`).
3. Promote first version in platform and deploy to staging, then run platform smoke checks.
