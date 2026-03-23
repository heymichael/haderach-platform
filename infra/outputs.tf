output "vendors_api_url" {
  description = "URL of the vendors-api Cloud Run service"
  value       = google_cloud_run_v2_service.vendors_api.uri
}

output "stocks_api_url" {
  description = "URL of the stocks-api Cloud Run service"
  value       = google_cloud_run_v2_service.stocks_api.uri
}

output "agent_api_url" {
  description = "URL of the agent-api Cloud Run service"
  value       = google_cloud_run_v2_service.agent_api.uri
}

output "artifact_registry_repo" {
  description = "Docker image registry path"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.apps.repository_id}"
}

output "app_artifacts_bucket" {
  description = "GCS bucket for app build artifacts"
  value       = google_storage_bucket.app_artifacts.name
}
