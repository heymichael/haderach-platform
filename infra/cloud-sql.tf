# ---------------------------------------------------------------------------
# Cloud SQL — Postgres instance for vendor/spend/user/app data
# ---------------------------------------------------------------------------

resource "google_sql_database_instance" "main" {
  name             = "haderach-main"
  project          = var.project_id
  region           = var.region
  database_version = "POSTGRES_15"

  settings {
    tier              = "db-f1-micro"
    availability_type = "ZONAL"
    disk_size         = 10
    disk_type         = "PD_SSD"

    ip_configuration {
      ipv4_enabled    = true
      require_ssl     = true
    }

    backup_configuration {
      enabled                        = true
      point_in_time_recovery_enabled = true
      start_time                     = "04:00"
      transaction_log_retention_days = 7

      backup_retention_settings {
        retained_backups = 7
      }
    }

    maintenance_window {
      day          = 7
      hour         = 5
      update_track = "stable"
    }
  }

  deletion_protection = true
}

resource "google_sql_database" "haderach" {
  name     = "haderach"
  project  = var.project_id
  instance = google_sql_database_instance.main.name
}

resource "google_sql_user" "app" {
  name     = "haderach-app"
  project  = var.project_id
  instance = google_sql_database_instance.main.name
  password = random_password.db_password.result
}

resource "random_password" "db_password" {
  length  = 32
  special = false
}

# ---------------------------------------------------------------------------
# Cloud SQL — Postgres instance for CMS content (separate from operational data)
# ---------------------------------------------------------------------------
# IAM approval: 2026-04-14T19:47, Michael Mader (task #227)

resource "google_sql_database_instance" "cms" {
  name             = "haderach-cms"
  project          = var.project_id
  region           = var.region
  database_version = "POSTGRES_15"

  settings {
    tier              = "db-f1-micro"
    availability_type = "ZONAL"
    disk_size         = 10
    disk_type         = "PD_SSD"

    ip_configuration {
      ipv4_enabled    = true
      require_ssl     = true
    }

    database_flags {
      name  = "log_checkpoints"
      value = "on"
    }

    database_flags {
      name  = "log_connections"
      value = "on"
    }

    database_flags {
      name  = "log_disconnections"
      value = "on"
    }

    database_flags {
      name  = "log_statement"
      value = "ddl"
    }

    database_flags {
      name  = "cloudsql.enable_pgaudit"
      value = "on"
    }

    database_flags {
      name  = "password_encryption"
      value = "scram-sha-256"
    }

    backup_configuration {
      enabled                        = true
      point_in_time_recovery_enabled = true
      start_time                     = "04:00"
      transaction_log_retention_days = 7

      backup_retention_settings {
        retained_backups = 7
      }
    }

    maintenance_window {
      day          = 7
      hour         = 5
      update_track = "stable"
    }
  }

  deletion_protection = true
}

resource "google_sql_database" "cms" {
  name     = "haderach-cms"
  project  = var.project_id
  instance = google_sql_database_instance.cms.name
}

resource "google_sql_user" "cms_app" {
  name     = "cms-app"
  project  = var.project_id
  instance = google_sql_database_instance.cms.name
  password = random_password.cms_db_password.result
}

resource "random_password" "cms_db_password" {
  length  = 32
  special = false
}
