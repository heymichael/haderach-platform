---
id: "028"
title: "Support task creation from workspaces without platform repo open"
status: pending
group: platform
phase: platform
priority: low
type: feature
tags: [tooling, taskmd, dx]
created: 2026-03-18
---

# Support task creation from workspaces without platform repo open

## Purpose

Currently, creating tasks from an app repo requires the platform repo to be open in the same workspace (since tasks live at `../haderach-platform/tasks/`). Support task creation even when the platform repo is not part of the active workspace.

## Approach

Investigate options:
1. Use an absolute path or environment variable (e.g. `HADERACH_PLATFORM_ROOT`) to locate the platform repo regardless of workspace layout.
2. Use the taskmd MCP server running from the platform repo to accept task creation requests over the protocol.
3. Use a git-based workflow where a task file is created locally and pushed to the platform repo via CLI.

Pick the simplest approach that preserves the "just works" experience.
