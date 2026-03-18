# ---------------------------------------------------------------------------
# Project-level IAM bindings (custom SAs only)
# ---------------------------------------------------------------------------
# Google-managed SA bindings (firebase agents, cloud build agents, etc.)
# are NOT managed here -- GCP owns those.

resource "google_project_iam_member" "deployer_hosting_admin" {
  project = var.project_id
  role    = "roles/firebasehosting.admin"
  member  = "serviceAccount:${google_service_account.platform_deployer.email}"
}

resource "google_project_iam_member" "mixpanel_bq_data_viewer" {
  project = var.project_id
  role    = "roles/bigquery.dataViewer"
  member  = "serviceAccount:${google_service_account.mixpanel_bigquery_reader.email}"
}

resource "google_project_iam_member" "mixpanel_bq_job_user" {
  project = var.project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.mixpanel_bigquery_reader.email}"
}
