# ---------------------------------------------------------------------------
# Cloud Run services
# ---------------------------------------------------------------------------

# --- vendors-api ---

resource "google_cloud_run_v2_service" "vendors_api" {
  name     = "vendors-api"
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
      image = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.apps.repository_id}/vendors-api:latest"

      ports {
        container_port = 8080
      }

      volume_mounts {
        name       = "cloudsql"
        mount_path = "/cloudsql"
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
        name = "VENDOR_AWS_BILLING_CREDENTIALS"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.vendor_aws_billing_credentials.secret_id
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
    google_secret_manager_secret_iam_member.vendors_api_secret_access,
    google_secret_manager_secret_iam_member.vendors_api_db_secret_access,
    google_secret_manager_secret_version.database_url,
  ]
}

resource "google_cloud_run_v2_service_iam_member" "vendors_api_public" {
  name     = google_cloud_run_v2_service.vendors_api.name
  location = var.region
  project  = var.project_id
  role     = "roles/run.invoker"
  member   = "allUsers"
}

resource "google_secret_manager_secret_iam_member" "vendors_api_secret_access" {
  secret_id = google_secret_manager_secret.vendor_aws_billing_credentials.secret_id
  project   = var.project_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${var.project_number}-compute@developer.gserviceaccount.com"
}

# --- agent-api ---

resource "google_cloud_run_v2_service" "agent_api" {
  name     = "agent-api"
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
      image = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.apps.repository_id}/agent-api:latest"

      ports {
        container_port = 8080
      }

      volume_mounts {
        name       = "cloudsql"
        mount_path = "/cloudsql"
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
        name = "OPENAI_API_KEY"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.openai_api_key.secret_id
            version = "latest"
          }
        }
      }

      env {
        name = "VENDOR_AWS_BILLING_CREDENTIALS"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.vendor_aws_billing_credentials.secret_id
            version = "latest"
          }
        }
      }

      env {
        name = "VENDOR_BILL_CREDENTIALS"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.vendor_bill_credentials.secret_id
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
    google_secret_manager_secret_iam_member.agent_api_secret_access,
    google_secret_manager_secret_iam_member.agent_api_bill_secret_access,
    google_secret_manager_secret_iam_member.vendors_api_secret_access,
    google_secret_manager_secret_iam_member.agent_api_db_secret_access,
    google_secret_manager_secret_version.database_url,
  ]
}

resource "google_cloud_run_v2_service_iam_member" "agent_api_public" {
  name     = google_cloud_run_v2_service.agent_api.name
  location = var.region
  project  = var.project_id
  role     = "roles/run.invoker"
  member   = "allUsers"
}

resource "google_secret_manager_secret_iam_member" "agent_api_secret_access" {
  secret_id = google_secret_manager_secret.openai_api_key.secret_id
  project   = var.project_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${var.project_number}-compute@developer.gserviceaccount.com"
}

resource "google_secret_manager_secret_iam_member" "agent_api_bill_secret_access" {
  secret_id = google_secret_manager_secret.vendor_bill_credentials.secret_id
  project   = var.project_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${var.project_number}-compute@developer.gserviceaccount.com"
}

resource "google_secret_manager_secret_iam_member" "agent_api_db_secret_access" {
  secret_id = google_secret_manager_secret.database_url.secret_id
  project   = var.project_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${var.project_number}-compute@developer.gserviceaccount.com"
}

resource "google_secret_manager_secret_iam_member" "vendors_api_db_secret_access" {
  secret_id = google_secret_manager_secret.database_url.secret_id
  project   = var.project_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${var.project_number}-compute@developer.gserviceaccount.com"
}

# --- stocks-api ---

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

  lifecycle {
    ignore_changes = [template[0].containers[0].image]
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
