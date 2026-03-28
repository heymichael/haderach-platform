---
id: "46"
title: "Extract ChatPanel into @haderach/shared-ui as a cross-app resource"
status: pending
group: platform
phase: platform
priority: high
type: improvement
tags: [shared-ui, chat, agent, cross-app, vendor-components]
effort: medium
created: 2026-03-23
---

## Purpose

The `ChatPanel` and `ChatToggle` components currently live in `vendors/src/` and are hardcoded for vendor management. The agent service (`agent/`) is already designed as a shared backend — its API accepts a `context.app` field to scope behavior. Extracting the chat UI into `@haderach/shared-ui` would let any app add an agent-powered chat panel with minimal wiring.

## Current state

- `vendors/src/ChatPanel.tsx` — right-side panel with message list, input, markdown rendering, confirm-delete overlay. Posts to `/agent/api/chat` with `context: { app: 'vendors' }`.
- `vendors/src/ChatToggle.tsx` — `MessageSquare` icon button to toggle the panel.
- Agent service at `agent/` — FastAPI + OpenAI tool-calling. Currently only has vendor tools, but the architecture supports app-scoped tool sets.

## Approach

1. Extract `ChatPanel` and `ChatToggle` into `packages/shared-ui/src/components/` in `haderach-home`.
2. Make the component generic — accept `appContext` (or similar) as a prop instead of hardcoding `{ app: 'vendors' }`. Accept an optional `onToolResult` callback for app-specific side effects (e.g., refreshing a vendor list after an add).
3. Extract `vendors/src/components/ui/dialog.tsx` (Radix Dialog primitive) into `packages/shared-ui/src/components/ui/dialog.tsx` — this is a generic shadcn-style primitive not yet in shared-ui that other apps would use.
4. Export all new components from `@haderach/shared-ui` barrel.
5. Update `vendors/src/App.tsx` to consume the shared components instead of local copies.
6. Optionally add the chat panel to other apps (card, stocks) as a follow-up.

## Design considerations

- The shared component should be agent-backend-agnostic about which tools exist — it just renders messages and relays responses.
- App-specific concerns (confirm-delete overlay, refresh callbacks) should be handled via props/slots, not baked into the shared component.
- The `react-markdown` dependency would need to be added to shared-ui's dependencies.
