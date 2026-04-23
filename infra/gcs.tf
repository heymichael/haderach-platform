# ---------------------------------------------------------------------------
# GCS Buckets
# ---------------------------------------------------------------------------

# Curated demo data — production-derived, owner-curated, developer-readable.
# See docs/demo-data-policy.md and docs/demo-data-runbook.md.
# Versioning enabled so a bad refresh can be rolled back without re-pulling production.
resource "google_storage_bucket" "demo_data" {
  name          = "haderach-demo-data"
  location      = "US"
  project       = var.project_id
  force_destroy = false

  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      age        = 90
      with_state = "ARCHIVED"
    }
    action {
      type = "Delete"
    }
  }
}

# Bucket IAM: demo-data — owner is the only writer (per demo-data-policy.md).
# IAM approval: 2026-04-22, Michael Mader (task #239)
resource "google_storage_bucket_iam_member" "demo_data_owner_admin" {
  bucket = google_storage_bucket.demo_data.name
  role   = "roles/storage.objectAdmin"
  member = "user:michael@haderach.ai"
}

# Bucket IAM: demo-data — developers in the haderach-developers-data group get read-only access.
# Group membership is managed in Google Workspace, not Terraform.
# IAM approval: 2026-04-22, Michael Mader (task #239)
resource "google_storage_bucket_iam_member" "demo_data_developers_viewer" {
  bucket = google_storage_bucket.demo_data.name
  role   = "roles/storage.objectViewer"
  member = "group:haderach-developers-data@haderach.ai"
}

resource "google_storage_bucket" "app_artifacts" {
  name          = "haderach-app-artifacts"
  location      = "US"
  project       = var.project_id
  force_destroy = false

  uniform_bucket_level_access = true

  lifecycle_rule {
    condition {
      age                = 90
      matches_prefix     = ["test-results/"]
    }
    action {
      type = "Delete"
    }
  }
}

# Bucket IAM: card-artifact-publisher can manage objects (create, view, overwrite)
resource "google_storage_bucket_iam_member" "card_publisher_admin" {
  bucket = google_storage_bucket.app_artifacts.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.card_artifact_publisher.email}"
}

# Bucket IAM: stocks-artifact-publisher can manage objects (create, view, overwrite)
resource "google_storage_bucket_iam_member" "stocks_publisher_admin" {
  bucket = google_storage_bucket.app_artifacts.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.stocks_artifact_publisher.email}"
}

# Bucket IAM: expenses-artifact-publisher can manage objects (create, view, overwrite)
resource "google_storage_bucket_iam_member" "expenses_publisher_admin" {
  bucket = google_storage_bucket.app_artifacts.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.expenses_artifact_publisher.email}"
}

# Bucket IAM: vendors-artifact-publisher can manage objects (create, view, overwrite)
resource "google_storage_bucket_iam_member" "vendors_publisher_admin" {
  bucket = google_storage_bucket.app_artifacts.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.vendors_artifact_publisher.email}"
}

# Bucket IAM: home-artifact-publisher can manage objects (create, view, overwrite)
resource "google_storage_bucket_iam_member" "home_publisher_admin" {
  bucket = google_storage_bucket.app_artifacts.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.home_artifact_publisher.email}"
}

# Bucket IAM: admin-system-artifact-publisher can manage objects (create, view, overwrite)
resource "google_storage_bucket_iam_member" "admin_system_publisher_admin" {
  bucket = google_storage_bucket.app_artifacts.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.admin_system_artifact_publisher.email}"
}

# Bucket IAM: admin-vendors-artifact-publisher can manage objects (create, view, overwrite)
resource "google_storage_bucket_iam_member" "admin_vendors_publisher_admin" {
  bucket = google_storage_bucket.app_artifacts.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.admin_vendors_artifact_publisher.email}"
}

# Bucket IAM: site-artifact-publisher can manage objects (create, view, overwrite)
# IAM approval: 2026-04-18, Michael Mader (task #240) — switched from Cloud Run to GCS
resource "google_storage_bucket_iam_member" "site_publisher_admin" {
  bucket = google_storage_bucket.app_artifacts.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.site_artifact_publisher.email}"
}

# Bucket IAM: test-results-publisher can manage objects under test-results/ only
resource "google_storage_bucket_iam_member" "test_results_publisher_admin" {
  bucket = google_storage_bucket.app_artifacts.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.test_results_publisher.email}"

  condition {
    title      = "test-results-prefix-only"
    expression = "resource.name.startsWith(\"projects/_/buckets/${google_storage_bucket.app_artifacts.name}/objects/test-results/\")"
  }
}

# Bucket IAM: test-results-publisher can list/read objects (needed for test_history queries)
resource "google_storage_bucket_iam_member" "test_results_publisher_viewer" {
  bucket = google_storage_bucket.app_artifacts.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.test_results_publisher.email}"
}

# Bucket IAM: platform-deployer can view objects (download artifacts)
resource "google_storage_bucket_iam_member" "deployer_viewer" {
  bucket = google_storage_bucket.app_artifacts.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.platform_deployer.email}"
}

# Bucket IAM: platform-deployer can read/write/overwrite objects (latest-deployed markers)
resource "google_storage_bucket_iam_member" "deployer_admin" {
  bucket = google_storage_bucket.app_artifacts.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.platform_deployer.email}"
}
