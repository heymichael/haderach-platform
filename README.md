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

```text
haderach-platform/
├── .cursor/
│   └── rules/
│       ├── architecture-pointer.mdc
│       ├── branch-safety-reminder.mdc
│       ├── repo-hygiene.mdc
│       └── todo-conventions.mdc
├── .github/
│   └── workflows/
│       └── deploy.yml
├── docs/
│   ├── architecture.md
│   └── app-registry.example.json
├── hosting/
│   └── public/
│       └── index.html
├── todo/
│   └── todo.md
├── .firebaserc
├── .gitignore
├── firebase.json
└── README.md
```

## Local development (placeholder commands)

Prerequisites:

- Node.js + npm
- Firebase CLI

Suggested commands:

```bash
npm --version
firebase --version
firebase emulators:start --only hosting
```

If you want a script wrapper later, add a minimal `package.json` with `dev:hosting` mapped to the emulator command.

## App repo integration model

Each app repo publishes immutable artifacts + metadata manifest.
Platform reads that manifest via the app registry contract and promotes a version per environment.

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
