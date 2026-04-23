---
status: draft
last-updated: 2026-04-23
related_tasks: ["230", "231"]
related_strategy: ["201"]
---

# Draft enterprise security package

This document is the first-pass umbrella draft for the enterprise security
documentation package. It is intentionally not final and is not ready for
external distribution without review. Its purpose is to create a concrete
artifact that clarifies what Haderach can already claim, what still depends on
implementation work, and what documents should exist in the final package.

## Intended package contents

The final enterprise security package is expected to include:

1. A data handling policy
2. A lightweight DPA template
3. Pre-filled security questionnaire responses
4. An Azure AI Foundry compatibility note
5. An approved AI list submission template

## Current framing

This draft should be treated as the top-level package overview, not the final
set of customer-facing materials. It exists to:

- define the package structure
- separate current-state claims from future-state goals
- identify where task `230` is a prerequisite for stronger claims
- give strategy `201` a concrete artifact to react to before creating more chores

## Current-state vs future-state claims

### Safe to claim now only if verified during drafting

- Current hosting and storage architecture
- Encryption in transit and at rest
- Existing authentication and access-control patterns
- Existing auditability and operational controls
- Current model-provider routing options

### Must be framed as in progress / not yet claimable until built

- Full client-data hiving / dedicated isolation options
- Hard delete across all relevant storage systems
- Formalized training opt-out guarantees across all model providers
- Enterprise-ready data residency commitments
- Any statement implying completed enterprise review readiness

## Draft sections to complete

### 1. Data handling policy

Needed topics:

- tenant isolation
- data retention
- hard delete
- training opt-out
- subprocessors / third-party model usage
- data residency

Drafting rule: every statement should be marked either "current state" or
"target state / pending capability" until fully validated.

### 2. DPA template

Needed topics:

- parties and purpose
- categories of processed data
- processor / subprocessor language
- security commitments
- deletion / return of data
- incident notification

Drafting rule: keep lightweight and aligned to actual operating model.

### 3. Security questionnaire responses

Needed topics:

- authentication and authorization
- encryption
- secrets handling
- logging / incident response
- testing posture
- SOC 2 / certification status

Drafting rule: prefer short, auditable answers over aspirational language.

### 4. Azure AI Foundry compatibility note

Needed topics:

- Foundry / Azure OpenAI / Azure Anthropic as model backend path
- what changes are configuration only vs architectural
- known constraints or blockers
- whether private endpoint / VNet-only requirements would block current hosting

### 5. Approved AI list submission template

Needed topics:

- short product summary
- data handling summary
- deployment / model-provider options
- security contact / review follow-up path

## Open questions for strategy 201

- Should the final package be one document with appendices, or a folder of
  separate artifacts with a short cover memo?
- Which claims can be made now without waiting on task `230`?
- How should "supported deployment models" be described without overcommitting
  to private-cloud capabilities that are still strategic rather than built?
- What evidence should be collected alongside the docs so enterprise reviews
  are not purely narrative?

## Exit condition for this draft

This draft is complete when it gives a clear structure for the final package,
identifies the major claim boundaries, and provides a concrete starting point
for strategy and follow-on implementation planning.
