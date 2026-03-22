# ---------------------------------------------------------------------------
# Secret Manager
# ---------------------------------------------------------------------------
# Terraform manages the secret entries and IAM. Actual secret values are
# set manually via:
#   echo -n "<value>" | gcloud secrets versions add <SECRET_ID> --data-file=-

resource "google_secret_manager_secret" "anthropic_api_key" {
  secret_id = "ANTHROPIC_API_KEY"
  project   = var.project_id

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret" "firebase_service_account" {
  secret_id = "FIREBASE_SERVICE_ACCOUNT"
  project   = var.project_id

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret" "mixpanel_bigquery_sa_api" {
  secret_id = "MIXPANEL_BIGQUERY_SERVICE_ACCOUNT_API"
  project   = var.project_id

  replication {
    auto {}
  }
}

# For vendors app Cloud Run service (AWS billing API credentials as JSON blob)
resource "google_secret_manager_secret" "vendor_aws_billing_credentials" {
  secret_id = "VENDOR_AWS_BILLING_CREDENTIALS"
  project   = var.project_id

  replication {
    auto {}
  }
}

# For stocks app Cloud Run service
resource "google_secret_manager_secret" "massive_api_key" {
  secret_id = "MASSIVE_API_KEY"
  project   = var.project_id

  replication {
    auto {}
  }
}
