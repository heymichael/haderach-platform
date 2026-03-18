terraform {
  required_version = ">= 1.5.0"

  backend "gcs" {
    bucket = "haderach-terraform-state"
    prefix = "platform"
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

data "google_project" "current" {
  project_id = var.project_id
}

# Note: the state bucket (haderach-terraform-state) is intentionally NOT
# managed here. Terraform cannot safely manage the bucket that stores its
# own state -- a terraform destroy would delete the state file.
