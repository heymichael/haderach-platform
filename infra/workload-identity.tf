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

# heymichael/stocks repo can impersonate stocks-artifact-publisher
resource "google_service_account_iam_member" "stocks_wif_binding" {
  service_account_id = google_service_account.stocks_artifact_publisher.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/projects/${var.project_number}/locations/global/workloadIdentityPools/github-actions/attribute.repository/heymichael/stocks"
}

# heymichael/vendors repo can impersonate vendors-artifact-publisher
resource "google_service_account_iam_member" "vendors_wif_binding" {
  service_account_id = google_service_account.vendors_artifact_publisher.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/projects/${var.project_number}/locations/global/workloadIdentityPools/github-actions/attribute.repository/heymichael/vendors"
}

# heymichael/haderach-home repo can impersonate home-artifact-publisher
resource "google_service_account_iam_member" "home_wif_binding" {
  service_account_id = google_service_account.home_artifact_publisher.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/projects/${var.project_number}/locations/global/workloadIdentityPools/github-actions/attribute.repository/heymichael/haderach-home"
}

# heymichael/agent repo can impersonate agent-artifact-publisher
resource "google_service_account_iam_member" "agent_wif_binding" {
  service_account_id = google_service_account.agent_artifact_publisher.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/projects/${var.project_number}/locations/global/workloadIdentityPools/github-actions/attribute.repository/heymichael/agent"
}

# heymichael/haderach-platform repo can impersonate platform-deployer
resource "google_service_account_iam_member" "platform_wif_binding" {
  service_account_id = google_service_account.platform_deployer.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/projects/${var.project_number}/locations/global/workloadIdentityPools/github-actions/attribute.repository/heymichael/haderach-platform"
}
