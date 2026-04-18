# ---------------------------------------------------------------------------
# Service Accounts (custom, user-created)
# ---------------------------------------------------------------------------
# Google-managed SAs (firebase-adminsdk, compute default, etc.) are NOT
# managed here -- GCP owns their lifecycle.

resource "google_service_account" "card_artifact_publisher" {
  account_id   = "card-artifact-publisher"
  display_name = "card-artifact-publisher"
  project      = var.project_id
}

resource "google_service_account" "stocks_artifact_publisher" {
  account_id   = "stocks-artifact-publisher"
  display_name = "stocks-artifact-publisher"
  project      = var.project_id
}

resource "google_service_account" "expenses_artifact_publisher" {
  account_id   = "expenses-artifact-publisher"
  display_name = "expenses-artifact-publisher"
  project      = var.project_id
}

resource "google_service_account" "vendors_artifact_publisher" {
  account_id   = "vendors-artifact-publisher"
  display_name = "vendors-artifact-publisher"
  project      = var.project_id
}

resource "google_service_account" "home_artifact_publisher" {
  account_id   = "home-artifact-publisher"
  display_name = "home-artifact-publisher"
  project      = var.project_id
}

resource "google_service_account" "platform_deployer" {
  account_id   = "haderach-platform-deployer"
  display_name = "haderach-platform-deployer"
  description  = "eploy workflow for haderach-platform repo (Firebase Hosting + GCS artifact reads)"
  project      = var.project_id
}

resource "google_service_account" "agent_artifact_publisher" {
  account_id   = "agent-artifact-publisher"
  display_name = "agent-artifact-publisher"
  project      = var.project_id
}

resource "google_service_account" "admin_system_artifact_publisher" {
  account_id   = "admin-sys-artifact-publisher"
  display_name = "admin-system-artifact-publisher"
  project      = var.project_id
}

resource "google_service_account" "admin_vendors_artifact_publisher" {
  account_id   = "admin-vend-artifact-publisher"
  display_name = "admin-vendors-artifact-publisher"
  project      = var.project_id
}

resource "google_service_account" "mixpanel_bigquery_reader" {
  account_id   = "mixpanel-bigquery-reader"
  display_name = "mixpanel-bigquery-reader"
  project      = var.project_id
}

resource "google_service_account" "test_results_publisher" {
  account_id   = "test-results-publisher"
  display_name = "test-results-publisher"
  description  = "Uploads pytest/Playwright JSON test reports to GCS (CI via WIF, local via JSON key)"
  project      = var.project_id
}

resource "google_service_account" "agent_local_dev" {
  account_id   = "agent-local-dev"
  display_name = "agent-local-dev"
  description  = "Local development SA for agent service (Cloud SQL Proxy, Firebase Auth)"
  project      = var.project_id
}

# IAM approval: 2026-04-14T19:47, Michael Mader (task #227)
resource "google_service_account" "cms_api_runner" {
  account_id   = "cms-api-runner"
  display_name = "cms-api-runner"
  description  = "Cloud Run runtime identity for cms-api (Payload CMS service)"
  project      = var.project_id
}

resource "google_service_account" "cms_artifact_publisher" {
  account_id   = "cms-artifact-publisher"
  display_name = "cms-artifact-publisher"
  description  = "CI/CD image push for haderach-cms repo"
  project      = var.project_id
}

# IAM approval: 2026-04-18, Michael Mader (task #240)
# Updated: switched from Cloud Run to GCS artifact deployment
resource "google_service_account" "site_artifact_publisher" {
  account_id   = "site-artifact-publisher"
  display_name = "site-artifact-publisher"
  description  = "CI/CD artifact upload for heymichael/site repo"
  project      = var.project_id
}
