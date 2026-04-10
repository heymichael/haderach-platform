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
