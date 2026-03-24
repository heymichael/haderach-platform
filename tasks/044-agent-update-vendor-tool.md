---
id: "44"
title: "Add update_vendor tool to agent service"
status: pending
group: vendors
phase: vendors
priority: medium
type: feature
tags: [agent, openai, tools, firestore]
effort: small
created: 2026-03-22
---

## Purpose

The agent service has `add_vendor`, `get_vendor`, and `delete_vendor` tools, but no `update_vendor` tool. The Firestore helper (`firestore_client.update_vendor`) already exists — it just needs to be exposed as an OpenAI tool schema and wired into the tool handler so users can update vendor fields via chat.

## Approach

1. Add `update_vendor` JSON schema to `TOOL_DEFINITIONS` in `service/tools.py` (required: identifier; optional: any VendorInfo field to change).
2. Add `execute_update_vendor` handler that calls `firestore_client.update_vendor`.
3. Register it in `TOOL_HANDLERS`.
4. Update the system prompt in `service/prompts.py` to mention the update capability.
5. Update `docs/architecture.md` supported tools table.
