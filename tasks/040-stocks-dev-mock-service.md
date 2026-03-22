---
id: 40
title: Add MSW dev fixture for stocks API mocking
group: stocks
phase: stocks
status: pending
priority: normal
depends_on: []
---

## Goal

Replace the inline `import.meta.env.DEV` mock guard in `App.tsx` `handleFetch` with a proper MSW (Mock Service Worker) setup that intercepts `/stocks/api/fx-range` during local development.

## Context

The current workaround uses a `import.meta.env.DEV` branch inside `handleFetch` to return mock data with simulated latency when the backend isn't running. This exercises the real async render path (loading → data) and is tree-shaken from production builds, but it's still inline application code that conflates dev tooling with production logic.

MSW would:
- Intercept the real `fetch` call at the network level, so the entire fetch path is exercised unchanged
- Live in a dedicated `src/mocks/` directory, fully separated from app code
- Support multiple response scenarios (success, empty, error) via handler configuration
- Be conditionally started only in development (`main.tsx` guard)

## Acceptance criteria

- [ ] `msw` added as a devDependency
- [ ] `src/mocks/handlers.ts` with a handler for `GET /stocks/api/fx-range` returning realistic mock data
- [ ] `src/mocks/browser.ts` setting up the MSW service worker
- [ ] `main.tsx` conditionally starts MSW in dev mode before rendering
- [ ] `public/mockServiceWorker.js` generated via `npx msw init public/`
- [ ] Remove the `import.meta.env.DEV` guard from `App.tsx` `handleFetch`
- [ ] Verify: `npm run dev` → Fetch button works end-to-end with mock data, loading spinner shows, table/chart render
- [ ] Verify: `npm run build` produces no MSW artifacts or references
