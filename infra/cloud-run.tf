# ---------------------------------------------------------------------------
# Cloud Run services (NEW -- stocks-api)
# ---------------------------------------------------------------------------

resource "google_cloud_run_v2_service" "stocks_api" {
  name     = "stocks-api"
  location = var.region
  project  = var.project_id

  template {
    containers {
      image = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.apps.repository_id}/stocks-api:latest"

      ports {
        container_port = 8080
      }

      env {
        name = "MASSIVE_API_KEY"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.massive_api_key.secret_id
            version = "latest"
          }
        }
      }

      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
      }
    }

    scaling {
      min_instance_count = 0
      max_instance_count = 2
    }
  }

  depends_on = [
    google_secret_manager_secret_iam_member.stocks_api_secret_access,
  ]
}

# Allow unauthenticated access (public API, fronted by Firebase Hosting)
resource "google_cloud_run_v2_service_iam_member" "stocks_api_public" {
  name     = google_cloud_run_v2_service.stocks_api.name
  location = var.region
  project  = var.project_id
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# Grant the default compute SA access to the MASSIVE_API_KEY secret
resource "google_secret_manager_secret_iam_member" "stocks_api_secret_access" {
  secret_id = google_secret_manager_secret.massive_api_key.secret_id
  project   = var.project_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${var.project_number}-compute@developer.gserviceaccount.com"
}
