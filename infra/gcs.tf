# ---------------------------------------------------------------------------
# GCS Buckets
# ---------------------------------------------------------------------------

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
