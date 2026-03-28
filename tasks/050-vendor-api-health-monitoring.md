---
id: "50"
title: "Add vendor API health monitoring (logging, deep check, alerting)"
status: done
group: vendors
phase: vendors
priority: medium
type: feature
tags: [vendors, monitoring, health-check, alerting]
effort: medium
---

# Add vendor API health monitoring

## Context

As the vendor count grows from 1 to 6 (task 048), the failure surface area for third-party API calls increases. Credential expiry, upstream outages, and breaking API changes can go undetected until a user manually fetches spend data.

## Plan

Full implementation plan with architecture diagram and file-level details:

`/Users/michaelmader_1/.cursor/plans/vendor_api_health_monitoring_c9aad567.plan.md`

## Summary

1. **Structured logging** — JSON-structured logs in each fetcher (vendor, status, latency, error type) emitted to Cloud Logging via stdout
2. **Deep health endpoint** — `GET /vendors/api/health?deep=true` probes every vendor in `FETCHER_REGISTRY` and reports per-vendor status
3. **Cloud Run startup probe** — shallow health check (`/vendors/api/health`) as a startup probe in Terraform
4. **Cloud Scheduler cron** — daily deep health check at 6 AM UTC
5. **Log-based alerting** — two GCP alert policies: vendor fetch failures (reactive) and deep health degraded (proactive)

## Dependencies

- Task 048 (fetcher registry refactor) — deep health iterates `FETCHER_REGISTRY`
