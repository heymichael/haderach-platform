# ---------------------------------------------------------------------------
# Artifact Registry (NEW -- for app backend Docker images)
# ---------------------------------------------------------------------------

resource "google_artifact_registry_repository" "apps" {
  location      = var.region
  repository_id = "haderach-apps"
  format        = "DOCKER"
  description   = "Docker images for haderach app backends"
  project       = var.project_id
}

resource "google_artifact_registry_repository_iam_member" "agent_publisher_ar_writer" {
  location   = google_artifact_registry_repository.apps.location
  repository = google_artifact_registry_repository.apps.repository_id
  project    = var.project_id
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${google_service_account.agent_artifact_publisher.email}"
}

resource "google_artifact_registry_repository_iam_member" "cms_publisher_ar_writer" {
  location   = google_artifact_registry_repository.apps.location
  repository = google_artifact_registry_repository.apps.repository_id
  project    = var.project_id
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${google_service_account.cms_artifact_publisher.email}"
}

# IAM approval: 2026-04-18, Michael Mader (task #240)
resource "google_artifact_registry_repository_iam_member" "site_publisher_ar_writer" {
  location   = google_artifact_registry_repository.apps.location
  repository = google_artifact_registry_repository.apps.repository_id
  project    = var.project_id
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${google_service_account.site_artifact_publisher.email}"
}
