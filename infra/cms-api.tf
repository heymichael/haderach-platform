# ---------------------------------------------------------------------------
# Cloud Run — CMS API (Payload CMS service)
# IAM approval: 2026-04-14T19:47, Michael Mader (task #227)
# ---------------------------------------------------------------------------

resource "google_cloud_run_v2_service" "cms_api" {
  name     = "cms-api"
  location = var.region
  project  = var.project_id

  template {
    service_account = google_service_account.cms_api_runner.email

    volumes {
      name = "cloudsql"
      cloud_sql_instance {
        instances = [google_sql_database_instance.cms.connection_name]
      }
    }

    containers {
      image = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.apps.repository_id}/cms-api:latest"

      ports {
        container_port = 3000
      }

      volume_mounts {
        name       = "cloudsql"
        mount_path = "/cloudsql"
      }

      env {
        name = "DATABASE_URL"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.cms_database_url.secret_id
            version = "latest"
          }
        }
      }

      env {
        name = "PAYLOAD_SECRET"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.payload_secret.secret_id
            version = "latest"
          }
        }
      }

      env {
        name = "PREVIEW_TOKEN_SECRET"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.preview_token_secret.secret_id
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

  lifecycle {
    ignore_changes = [template[0].containers[0].image]
  }

  depends_on = [
    google_secret_manager_secret_iam_member.cms_api_runner_db_url,
    google_secret_manager_secret_iam_member.cms_api_runner_payload_secret,
    google_secret_manager_secret_iam_member.cms_api_runner_preview_token_secret,
    google_secret_manager_secret_version.cms_database_url,
  ]
}

resource "google_cloud_run_v2_service_iam_member" "cms_api_public" {
  name     = google_cloud_run_v2_service.cms_api.name
  location = var.region
  project  = var.project_id
  role     = "roles/run.invoker"
  member   = "allUsers"
}
