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
