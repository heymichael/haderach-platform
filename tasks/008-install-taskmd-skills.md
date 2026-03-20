---
id: "008"
title: "Install taskmd skills and MCP server"
status: cancelled
group: platform
phase: platform
priority: low
type: chore
tags: [tooling, taskmd]
created: 2026-03-13
---

# Install taskmd skills and MCP server

## Purpose

Enable taskmd slash commands and MCP tooling in the platform repo so AI assistants can create, update, and manage tasks directly from any workspace that includes the platform repo.

## Approach

1. Add the taskmd marketplace and install the slash command skills (`/taskmd:do-task`, `/taskmd:next-task`, etc.) at project scope in the platform repo.
2. Optionally install the `taskmd-mcp` server for direct tool access.
3. Document the setup in the platform README or contributing guide so other contributors can onboard.
