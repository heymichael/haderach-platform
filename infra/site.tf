# ---------------------------------------------------------------------------
# Cloud Run — Site (Vite SPA frontend, served via nginx)
# IAM approval: 2026-04-18, Michael Mader (task #240)
# ---------------------------------------------------------------------------

resource "google_cloud_run_v2_service" "site_api" {
  name     = "site-api"
  location = var.region
  project  = var.project_id

  template {
    service_account = google_service_account.site_runner.email

    containers {
      image = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.apps.repository_id}/site-api:latest"

      ports {
        container_port = 8080
      }

      resources {
        limits = {
          cpu    = "1"
          memory = "256Mi"
        }
      }
    }

    scaling {
      min_instance_count = 0
      max_instance_count = 2
    }
  }

  lifecycle {
    ignore_changes = [template[0].containers[0].image]
  }
}

resource "google_cloud_run_v2_service_iam_member" "site_api_public" {
  name     = google_cloud_run_v2_service.site_api.name
  location = var.region
  project  = var.project_id
  role     = "roles/run.invoker"
  member   = "allUsers"
}
