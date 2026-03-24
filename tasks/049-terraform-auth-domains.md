---
id: "49"
title: "Add Firebase Auth authorized domains to Terraform"
status: pending
group: platform
phase: platform
priority: high
type: fix
tags: [terraform, firebase, auth, infrastructure]
effort: small
---

# Add Firebase Auth authorized domains to Terraform

## Context

Firebase Auth authorized domains (the OAuth redirect allowlist) are currently
managed only through the Firebase Console UI with no IaC backing. This caused a
production outage where `haderach.ai` was missing from the list, blocking all
new sign-ins with a cryptic minified error (`e is not iterable`). Previously
authenticated sessions continued working because session restoration doesn't
invoke `signInWithPopup` / origin validation.

## Task

Add a `google_identity_platform_config` resource to `infra/` that declares the
authorized domains (`haderach.ai`, `localhost`) so that `terraform apply`
restores them if they are ever removed.

## Acceptance criteria

- [ ] `google_identity_platform_config` resource in platform Terraform manages `authorized_domains`
- [ ] `haderach.ai` and `localhost` are declared in the resource
- [ ] `terraform plan` shows no diff against current console state
- [ ] Existing sign-in flow remains functional after apply
