# ---------------------------------------------------------------------------
# GCS Buckets
# ---------------------------------------------------------------------------

resource "google_storage_bucket" "app_artifacts" {
  name          = "haderach-app-artifacts"
  location      = "US"
  project       = var.project_id
  force_destroy = false

  uniform_bucket_level_access = true
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

# Bucket IAM: home-artifact-publisher can manage objects (create, view, overwrite)
resource "google_storage_bucket_iam_member" "home_publisher_admin" {
  bucket = google_storage_bucket.app_artifacts.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.home_artifact_publisher.email}"
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
