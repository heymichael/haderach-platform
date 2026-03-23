---
id: "045"
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

## Remaining items

- [ ] **Firestore PITR** — enable point-in-time recovery via Terraform or console
- [ ] **Agent repo scaffold** — create the `agent` repo with FastAPI service structure, Dockerfile, and CI workflow
- [ ] **Agent tool definitions** — define OpenAI tool schemas for add_vendor, update_vendor, get_vendor and write the system prompt
- [ ] **Agent tool execution** — implement Python handlers that perform Firestore CRUD via firestore_client.py
- [ ] **Agent platform infra** — Cloud Run TF, service account, Firebase Hosting rewrite. Import existing OPENAI_API_KEY secret into TF state
- [ ] **Chat panel** — build ChatPanel and ChatToggle in vendors app: right-side panel, message list, input, API integration, toggle open/close with layout resize

## Reference

Plan document: `.cursor/plans/vendors_chat_agent_phase_6a55a168.plan.md`
