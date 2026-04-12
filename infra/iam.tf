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

# agent-artifact-publisher needs run.developer to deploy new revisions
resource "google_project_iam_member" "agent_publisher_run_developer" {
  project = var.project_id
  role    = "roles/run.developer"
  member  = "serviceAccount:${google_service_account.agent_artifact_publisher.email}"
}

# agent-artifact-publisher needs to act-as the default compute SA when deploying
resource "google_service_account_iam_member" "agent_publisher_act_as_compute" {
  service_account_id = "projects/${var.project_id}/serviceAccounts/${var.project_number}-compute@developer.gserviceaccount.com"
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.agent_artifact_publisher.email}"
}

# Default compute SA needs cloudsql.client for Cloud SQL Auth Proxy
resource "google_project_iam_member" "compute_cloudsql_client" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${var.project_number}-compute@developer.gserviceaccount.com"
}

# agent-local-dev needs cloudsql.client for local Cloud SQL Proxy
resource "google_project_iam_member" "agent_local_dev_cloudsql_client" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.agent_local_dev.email}"
}

# agent-local-dev needs firebaseauth.admin for local ID token verification
resource "google_project_iam_member" "agent_local_dev_firebase_auth" {
  project = var.project_id
  role    = "roles/firebaseauth.admin"
  member  = "serviceAccount:${google_service_account.agent_local_dev.email}"
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

# agent-artifact-publisher needs cloudsql.client for SchemaSpy doc generation workflow
resource "google_project_iam_member" "agent_artifact_publisher_cloudsql_client" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.agent_artifact_publisher.email}"
}

# agent-artifact-publisher needs DATABASE_URL secret for SchemaSpy doc generation
resource "google_secret_manager_secret_iam_member" "agent_artifact_publisher_database_url" {
  secret_id = google_secret_manager_secret.database_url.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.agent_artifact_publisher.email}"
}
