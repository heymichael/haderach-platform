# ---------------------------------------------------------------------------
# Cloud Run — Digital Media API (asset management and search service)
# IAM approval: 2026-04-29, Michael Mader (task #300)
# ---------------------------------------------------------------------------

resource "google_cloud_run_v2_service" "digital_media_api" {
  name     = "digital-media-api"
  location = var.region
  project  = var.project_id

  template {
    service_account = google_service_account.digital_media_api_runner.email

    volumes {
      name = "cloudsql"
      cloud_sql_instance {
        instances = [google_sql_database_instance.digital_media.connection_name]
      }
    }

    containers {
      image = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.apps.repository_id}/digital-media-api:latest"

      ports {
        container_port = 8000
      }

      volume_mounts {
        name       = "cloudsql"
        mount_path = "/cloudsql"
      }

      env {
        name = "DATABASE_URL"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.digital_media_database_url.secret_id
            version = "latest"
          }
        }
      }

      env {
        name  = "GCS_BUCKET_PREFIX"
        value = "haderach-media"
      }

      env {
        name  = "VERTEX_PROJECT"
        value = var.project_id
      }

      env {
        name  = "VERTEX_LOCATION"
        value = var.region
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

  lifecycle {
    ignore_changes = [template[0].containers[0].image]
  }

  depends_on = [
    google_secret_manager_secret_iam_member.digital_media_runner_db_url,
    google_secret_manager_secret_version.digital_media_database_url,
  ]
}

resource "google_cloud_run_v2_service_iam_member" "digital_media_api_public" {
  name     = google_cloud_run_v2_service.digital_media_api.name
  location = var.region
  project  = var.project_id
  role     = "roles/run.invoker"
  member   = "allUsers"
}
