---
name: fetch-artifact-sha
description: >-
  Fetch the latest published artifact commit SHA for app deployments.
  Use when the user asks for the latest SHA, latest artifact, deploy SHA,
  what's deployed, current deploy versions, what version is live,
  deployment SHAs, or wants to trigger a deploy and needs the commit hash.
---

# Fetch Latest Artifact SHA

## When to use

When the user asks about deployed versions, latest artifacts, deploy SHAs,
what's currently live, or needs the commit hash to trigger a deploy workflow.
Applies to any app: home, card, stocks, vendors.

## How to fetch

Run the script using its absolute path. This command **must** use
`required_permissions: ["all"]` because it needs gcloud network access,
git fetch to remotes, and GCS reads.

```bash
/Users/michaelmader_1/haderach_org/haderach_site/haderach-platform/scripts/latest-artifact-sha.sh          # all apps
/Users/michaelmader_1/haderach_org/haderach_site/haderach-platform/scripts/latest-artifact-sha.sh home     # single app
/Users/michaelmader_1/haderach_org/haderach_site/haderach-platform/scripts/latest-artifact-sha.sh card     # single app
/Users/michaelmader_1/haderach_org/haderach_site/haderach-platform/scripts/latest-artifact-sha.sh stocks   # single app
/Users/michaelmader_1/haderach_org/haderach_site/haderach-platform/scripts/latest-artifact-sha.sh vendors  # single app
```

Requires `gcloud` authentication (`gcloud auth application-default login`).

The script checks each app repo's `origin/main` HEAD and verifies the
corresponding artifact exists in `gs://haderach-app-artifacts/<app_id>/versions/`.

## Output format

```
home: abc123def456...
card: 789xyz...
stocks: def987...
vendors: abc987...
```

## Using the SHA for deploys

The SHA is used as the `commit_sha` input when triggering the platform deploy
workflow (`.github/workflows/deploy.yml`) via GitHub Actions manual dispatch.
