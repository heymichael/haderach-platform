# ---------------------------------------------------------------------------
# Workload Identity Federation (GitHub Actions -> GCP)
# ---------------------------------------------------------------------------

resource "google_iam_workload_identity_pool" "github_actions" {
  workload_identity_pool_id = "github-actions"
  display_name              = "github-actions"
  project                   = var.project_id
}

resource "google_iam_workload_identity_pool_provider" "github_actions" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_actions.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-actions"
  display_name                       = "github-actions"
  project                            = var.project_id

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
  }

  attribute_condition = "assertion.sub != \"\""

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
    allowed_audiences = [
      "https://iam.googleapis.com/projects/${var.project_number}/locations/global/workloadIdentityPools/github-actions/providers/github-actions"
    ]
  }
}

# heymichael/card repo can impersonate card-artifact-publisher
resource "google_service_account_iam_member" "card_wif_binding" {
  service_account_id = google_service_account.card_artifact_publisher.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/projects/${var.project_number}/locations/global/workloadIdentityPools/github-actions/attribute.repository/heymichael/card"
}

# heymichael/haderach-platform repo can impersonate platform-deployer
resource "google_service_account_iam_member" "platform_wif_binding" {
  service_account_id = google_service_account.platform_deployer.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/projects/${var.project_number}/locations/global/workloadIdentityPools/github-actions/attribute.repository/heymichael/haderach-platform"
}
