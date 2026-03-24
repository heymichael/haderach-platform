---
id: "11"
title: "Evolve deploy trigger to PR-promote or event-driven"
status: cancelled
group: platform
phase: platform
priority: medium
type: improvement
tags: [ci, deploy]
created: 2026-03-03
---

# Evolve deploy trigger to PR-promote or event-driven

## Purpose

Replace the manual-dispatch deploy workflow with a more auditable and automated trigger so deployments have a clear review trail and/or happen automatically on artifact publication.

## Approach

Evaluate two models: (A) PR-promote, where a version manifest file is checked into the platform repo and updating it via PR triggers deploy on merge; (B) event-driven, where the card repo sends a repository_dispatch event to the platform repo after artifact publish, triggering deploy automatically. PR-promote gives audit trail and rollback simplicity. Event-driven reduces manual steps. Implement the chosen model and update `docs/architecture.md` accordingly.
