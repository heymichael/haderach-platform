---
id: "45"
title: "Complete Vendors Chat Agent Phase"
status: in-progress
group: vendors
phase: vendors
priority: high
type: feature
tags: [firestore, agent, chat, openai]
effort: large
created: 2026-03-22
---

## Purpose

Complete the remaining workstreams of the Vendors Chat Agent Phase plan. Workstream 1 (Firestore migration) and the vendor detail dialog conversion are done. The remaining work covers the agent service, platform infra, chat UI, and Firestore PITR.

## Completed items

- [x] **Agent repo scaffold** — `agent/` repo created with FastAPI service, Dockerfile, CI workflow (`publish-artifact.yml`), docs, README
- [x] **Agent tool definitions** — `tools.py` defines `add_vendor`, `delete_vendor`, `get_vendor` schemas; `prompts.py` has system prompt
- [x] **Agent tool execution** — `tools.py` handlers + `firestore_client.py` with full CRUD (`add_vendor`, `update_vendor`, `get_vendor`, `delete_vendor`, `resolve_vendor`)
- [x] **Agent platform infra** — Cloud Run TF (`agent-api`), `OPENAI_API_KEY` in `secrets.tf`, service account, Firebase Hosting rewrite `/agent/api/**`
- [x] **Chat panel** — `ChatPanel.tsx` and `ChatToggle.tsx` built in vendors app; integrated in `App.tsx` with toggle state

## Remaining items

- [ ] **Firestore PITR** — enable point-in-time recovery via Terraform (see task #042)

## Reference

Plan document: `.cursor/plans/vendors_chat_agent_phase_6a55a168.plan.md`
