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

# AWS billing API credentials (JSON blob) — used by vendors-api and agent-api
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

# For agent service Cloud Run (OpenAI tool-calling).
# This secret already exists in Secret Manager -- after adding this resource,
# run:  terraform import google_secret_manager_secret.openai_api_key projects/haderach-ai/secrets/OPENAI_API_KEY
resource "google_secret_manager_secret" "openai_api_key" {
  secret_id = "OPENAI_API_KEY"
  project   = var.project_id

  replication {
    auto {}
  }
}
