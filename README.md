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
│   ├── app-registry.example.json
│   ├── priorities/
│   │   └── index.html
│   └── shared/
│       ├── docs-shell.css
│       ├── docs-shell-page.template.html
│       └── docs-shell.js
├── hosting/
│   └── public/
│       ├── index.html
│       └── robots.txt
├── scripts/
│   ├── generate_priorities_docs.py
│   ├── requirements-docs.txt
│   └── sync_docs_card.sh
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
python3 scripts/generate_priorities_docs.py
bash scripts/sync_docs_card.sh
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

- `docs/index.html`
- `docs/shared/docs-shell.css`
- `docs/shared/docs-shell.js`
- `docs/shared/docs-shell-page.template.html`

Template replacement values per app:

- `__APP_NAME__` (for example `Card`)
- `__SIGNED_IN_LABEL__` (for example `card docs`)
- `__DOCS_BASE_PATH__` (for example `/card/docs`)

For strict tab parity, each app docs root should also include:

- `<base>/test-status/catalog.json`
- `<base>/priorities/index.html`
- `<base>/requirements/catalog.json`
- `<base>/testing/catalog.json`
- `<base>/architecture.md`

Architecture tab standard: `baseDocsPath + "/architecture.md"` for both platform and app docs shells.

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
