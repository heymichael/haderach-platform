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
