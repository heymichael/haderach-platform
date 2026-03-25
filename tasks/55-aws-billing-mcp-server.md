---
id: "55"
title: "MCP server for AWS Cost Explorer billing queries"
status: cancelled
group: vendors
phase: vendors
priority: medium
type: feature
tags: [mcp, aws, billing, cost-explorer, secrets]
effort: medium
created: 2026-03-24
---

## Purpose

Enable the team to query AWS Cost Explorer billing data (monthly spend, per-service breakdowns) directly from Cursor without passing raw credentials through chat. Credentials should be securely stored and never exposed to the LLM.

## Requirements

- Build an MCP server that wraps the AWS Cost Explorer API
- Expose tools such as `get_monthly_spend(months)` and `get_spend_by_service(month)`
- Support secure credential entry by the user (the user must be able to provide secret values safely, without them being visible to the LLM or stored in chat history)
- Read `VENDOR_AWS_BILLING_CREDENTIALS` from `.env` or a secrets manager
- Credentials structure: JSON with `access_key_id`, `secret_access_key`, `region`

## Approach

1. Design secure credential input flow (e.g., env-file-based, 1Password CLI, or interactive prompt that bypasses LLM context)
2. Implement MCP server with Cost Explorer tools
3. Configure Cursor MCP settings for team use
4. Document setup for team onboarding

## Open questions

- Preferred secrets backend (`.env`, 1Password CLI, AWS Secrets Manager, etc.)
- Whether to run the MCP server locally per-developer or host centrally
- Scope of additional tools beyond billing (e.g., resource inventory, alerts)
