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

resource "google_service_account" "mixpanel_bigquery_reader" {
  account_id   = "mixpanel-bigquery-reader"
  display_name = "mixpanel-bigquery-reader"
  project      = var.project_id
}
