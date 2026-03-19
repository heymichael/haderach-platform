---
name: fetch-artifact-sha
description: >-
  Fetch the latest published artifact commit SHA for app deployments.
  Use when the user asks for the latest SHA, latest artifact, deploy SHA,
  or wants to trigger a deploy and needs the commit hash.
---

# Fetch Latest Artifact SHA

## When to use

When the user asks for the latest artifact SHA for an app (card, stocks), or
needs the commit hash to trigger a deploy workflow.

## How to fetch

Run the script from the platform repo:

```bash
cd /Users/michaelmader_1/haderach_org/haderach_site/haderach-platform
./scripts/latest-artifact-sha.sh          # all apps
./scripts/latest-artifact-sha.sh card     # single app
./scripts/latest-artifact-sha.sh stocks   # single app
```

Requires `gcloud` authentication (`gcloud auth application-default login`).

The script lists versions in `gs://haderach-app-artifacts/<app_id>/versions/`
and returns the most recent commit SHA.

## Output format

```
card: abc123def456...
stocks: 789xyz...
```

## Using the SHA for deploys

The SHA is used as the `commit_sha` input when triggering the platform deploy
workflow (`.github/workflows/deploy.yml`) via GitHub Actions manual dispatch.
