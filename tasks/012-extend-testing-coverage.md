---
id: "012"
title: "Extend automatic testing coverage to all apps"
status: completed
group: platform
phase: platform
priority: medium
type: improvement
tags: [ci, testing]
created: 2026-03-03
---

# Extend automatic testing coverage to all apps

## Purpose

Extend automated testing beyond the card app so each app has appropriate app-specific tests while maintaining a single, consistent testing framework and workflow across the monorepo.

## Approach

Define and adopt a unified testing framework (commands, structure, reporting, CI integration, and quality gates) used consistently across all apps. Implement only app-specific test suites per app under that shared framework, so each app tests its own behavior while tooling, execution flow, and reporting remain standardized.
