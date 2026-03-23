---
id: "042"
title: "Enable Firestore point-in-time recovery"
status: cancelled
group: platform
phase: platform
priority: medium
type: improvement
tags: [firestore, disaster-recovery, terraform]
effort: small
created: 2026-03-22
---

## Purpose

Enable Firestore point-in-time recovery (PITR) on the `(default)` database so data can be restored to any point within the retention window.

## Approach

Add `point_in_time_recovery_enablement = "POINT_IN_TIME_RECOVERY_ENABLED"` to the `google_firestore_database.default` resource in `infra/firestore.tf`, then `terraform apply`.

Alternatively, enable via the GCP Console under Firestore → Settings → Point-in-time recovery.
