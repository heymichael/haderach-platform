# ---------------------------------------------------------------------------
# Project API enablement
# ---------------------------------------------------------------------------
# APIs are enabled here rather than via gcloud CLI to maintain infrastructure
# as code and audit trail for SOC2 compliance.

# Vertex AI API — required for embeddings (text-embedding-005) and Vision API
# Requested: task #300 Digital Media MVP (auto-tagging, semantic search)
resource "google_project_service" "aiplatform" {
  project = var.project_id
  service = "aiplatform.googleapis.com"

  disable_dependent_services = false
  disable_on_destroy         = false
}

# Cloud Vision API — required for image label detection (auto-tagging)
# Requested: task #300 Digital Media MVP
resource "google_project_service" "vision" {
  project = var.project_id
  service = "vision.googleapis.com"

  disable_dependent_services = false
  disable_on_destroy         = false
}
