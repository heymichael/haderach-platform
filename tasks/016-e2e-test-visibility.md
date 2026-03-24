---
id: "16"
title: "Improve deploy-time E2E test visibility in GitHub Actions"
status: cancelled
group: platform
phase: platform
priority: low
type: improvement
tags: [ci, testing, deploy]
created: 2026-03-03
---

# Improve deploy-time E2E test visibility in GitHub Actions

## Purpose

Reduce uncertainty during long deploys by making it clear where E2E execution is in progress and whether tests are actively advancing.

## Approach

Update CI test reporting to stream per-test progress in Action logs (for example using Playwright line reporter alongside HTML), define expected duration thresholds/alerts for the deploy test step, and add lightweight runbook guidance for when to cancel/retry stalled runs.
