---
id: "47"
title: "Add fuzzy vendor resolution to agent system prompt"
status: pending
group: home
phase: home
priority: medium
type: improvement
tags: [agent, prompt, ux]
effort: small
---

# Add fuzzy vendor resolution to agent system prompt

## Problem
Users have to type the exact stored vendor name (e.g. "Amazon Web Services") when looking up or deleting vendors. Common abbreviations like "AWS", "GCP", or "Mongo" return "not found", which is a poor experience.

## Proposed solution
Add a "Fuzzy vendor resolution" section to `VENDOR_AGENT_SYSTEM_PROMPT` in `agent/service/prompts.py` that instructs the model to:

1. When `get_vendor` or `delete_vendor` returns "not found", use general knowledge to expand the identifier (acronyms, shortened names, brand variants).
2. Retry the tool call once with the expanded name.
3. Only surface "not found" to the user if the retry also fails.

This requires no code changes — the existing 5-round tool-call loop in `app.py` already supports the retry naturally.

## Validation
- Test with common abbreviations: AWS, GCP, GH, DD, k8s, Mongo, Postgres.
- Confirm the retry fires only on "not found" and does not interfere with exact matches.
- Verify the agent still respects the one-tool-per-response rule (the retry is a second round, not a parallel call).
