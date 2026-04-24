# Cursor Rule Matrix

Last reviewed: 2026-04-24

This document tracks the current `.cursor/rules/*.mdc` coverage across the
workspace so rule sprawl and `alwaysApply` usage can be reviewed deliberately.

## How to read this

- `Yes` = the rule exists in that repo and `alwaysApply: true`
- `No` = the rule exists in that repo and `alwaysApply: false`
- blank = that repo does not have that rule

## Current matrix

| Rule | platform | tasks | agent | home | expenses | admin-system | admin-vendors | cms | content | site | stocks | vendors |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Agent Service API Authentication |  |  | No |  |  |  |  |  |  |  |  |  |
| Agent Test Suite |  |  | No |  |  |  |  |  |  |  |  |  |
| Agent-Tuning Conventions |  | No |  |  |  |  |  |  |  |  |  |  |
| Architecture Pointer | Yes |  | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes |
| Asset Records |  | No |  |  |  |  |  |  |  |  |  |  |
| Backend API Authentication Policy | No |  |  |  |  |  |  |  |  |  |  |  |
| Branch Safety | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes |
| Bug Tracking |  | No |  |  |  |  |  |  |  |  |  |  |
| CMS Auth Policy |  |  |  |  |  |  |  | No |  |  |  |  |
| Content Deployment |  |  |  |  |  |  |  |  | No |  |  |  |
| Cross-Repo Status | No |  | No | No | No | No | No | No |  | No | No | No |
| Dev Data Mocking |  |  |  |  |  |  |  |  |  |  | No |  |
| IAM Governance | Yes |  | Yes |  |  |  |  | Yes |  |  |  |  |
| Implementation Plan Conventions | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes |
| Input Records |  | No |  |  |  |  |  |  |  |  |  |  |
| Local Dev Testing | No |  |  |  | No |  |  |  |  | No |  | No |
| PR Conventions | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes |
| Repo Boundary / Hygiene | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes |
| Resource Records |  | No |  |  |  |  |  |  |  |  |  |  |
| Service-Oriented Data Access | No |  | No | No | No | No | No | No |  | No | No | No |
| Strategy Records |  | No |  |  |  |  |  |  |  |  |  |  |
| Task Lifecycle Timing |  | Yes |  |  |  |  |  |  |  |  |  |  |
| Task Management | Yes | No | No | No | No | No | No | No |  | No | No | No |
| Test Execution |  |  | No |  |  |  |  |  |  |  |  |  |
| Work Groups | No |  |  |  |  |  |  |  |  |  |  |  |

## Current policy

The current convention is:

- Keep `alwaysApply: true` for standing guardrails and repo-identity rules.
- Prefer `alwaysApply: false` for playbooks, conditional procedures, and
  heavier reference material.
- It is acceptable for a canonical rule and its lightweight pointer wrappers to
  use different `alwaysApply` values when that is intentional. The current
  `todo-conventions` setup is the main example.

## When to update this doc

Update this matrix when:

- a rule is added or removed in any repo
- a rule family changes from local to canonical-plus-pointer
- any `alwaysApply` value changes
- a repo is added to or removed from the workspace
