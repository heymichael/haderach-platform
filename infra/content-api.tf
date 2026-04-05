# ---------------------------------------------------------------------------
# Content API — authenticated static-file server for docs.haderach.ai
# ---------------------------------------------------------------------------

# --- GCS bucket for content files ---

resource "google_storage_bucket" "content_docs" {
  name          = "haderach-content-docs"
  location      = "US"
  project       = var.project_id
  force_destroy = false

  uniform_bucket_level_access = true
}

resource "google_storage_bucket_iam_member" "content_docs_reader" {
  bucket = google_storage_bucket.content_docs.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${var.project_number}-compute@developer.gserviceaccount.com"
}

resource "google_storage_bucket_iam_member" "content_docs_deployer" {
  bucket = google_storage_bucket.content_docs.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.platform_deployer.email}"
}

# --- Secrets ---

resource "google_secret_manager_secret" "content_oauth_client_id" {
  secret_id = "CONTENT_OAUTH_CLIENT_ID"
  project   = var.project_id

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret" "content_oauth_client_secret" {
  secret_id = "CONTENT_OAUTH_CLIENT_SECRET"
  project   = var.project_id

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret" "content_session_secret" {
  secret_id = "CONTENT_SESSION_SECRET"
  project   = var.project_id

  replication {
    auto {}
  }
}

resource "random_password" "content_session_secret" {
  length  = 64
  special = false
}

resource "google_secret_manager_secret_version" "content_session_secret" {
  secret      = google_secret_manager_secret.content_session_secret.id
  secret_data = random_password.content_session_secret.result
}

resource "google_secret_manager_secret_iam_member" "content_api_oauth_id_access" {
  secret_id = google_secret_manager_secret.content_oauth_client_id.secret_id
  project   = var.project_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${var.project_number}-compute@developer.gserviceaccount.com"
}

resource "google_secret_manager_secret_iam_member" "content_api_oauth_secret_access" {
  secret_id = google_secret_manager_secret.content_oauth_client_secret.secret_id
  project   = var.project_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${var.project_number}-compute@developer.gserviceaccount.com"
}

resource "google_secret_manager_secret_iam_member" "content_api_session_secret_access" {
  secret_id = google_secret_manager_secret.content_session_secret.secret_id
  project   = var.project_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${var.project_number}-compute@developer.gserviceaccount.com"
}

# --- Cloud Run service ---

resource "google_cloud_run_v2_service" "content_api" {
  name     = "content-api"
  location = var.region
  project  = var.project_id

  template {
    volumes {
      name = "cloudsql"
      cloud_sql_instance {
        instances = [google_sql_database_instance.main.connection_name]
      }
    }

    containers {
      image = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.apps.repository_id}/content-api:latest"

      ports {
        container_port = 8080
      }

      volume_mounts {
        name       = "cloudsql"
        mount_path = "/cloudsql"
      }

      env {
        name  = "CONTENT_BUCKET"
        value = google_storage_bucket.content_docs.name
      }

      env {
        name = "DATABASE_URL"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.database_url.secret_id
            version = "latest"
          }
        }
      }

      env {
        name = "OAUTH_CLIENT_ID"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.content_oauth_client_id.secret_id
            version = "latest"
          }
        }
      }

      env {
        name = "OAUTH_CLIENT_SECRET"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.content_oauth_client_secret.secret_id
            version = "latest"
          }
        }
      }

      env {
        name = "SESSION_SECRET"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.content_session_secret.secret_id
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
    google_secret_manager_secret_iam_member.content_api_oauth_id_access,
    google_secret_manager_secret_iam_member.content_api_oauth_secret_access,
    google_secret_manager_secret_iam_member.content_api_session_secret_access,
    google_secret_manager_secret_version.database_url,
  ]
}

resource "google_cloud_run_v2_service_iam_member" "content_api_public" {
  name     = google_cloud_run_v2_service.content_api.name
  location = var.region
  project  = var.project_id
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# --- Custom domain mapping ---

resource "google_cloud_run_domain_mapping" "docs" {
  name     = "docs.haderach.ai"
  location = var.region
  project  = var.project_id

  metadata {
    namespace = var.project_id
  }

  spec {
    route_name = google_cloud_run_v2_service.content_api.name
  }
}

# --- Cloud Scheduler warm-up ---

resource "google_cloud_scheduler_job" "content_warmup" {
  name      = "content-api-warmup"
  project   = var.project_id
  region    = var.region
  schedule  = "*/15 * * * *"
  time_zone = "America/New_York"

  http_target {
    uri         = "${google_cloud_run_v2_service.content_api.uri}/health"
    http_method = "GET"
  }
}
