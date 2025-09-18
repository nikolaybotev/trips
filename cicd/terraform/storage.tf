# Create GCS bucket for Dataflow temporary and staging files
resource "google_storage_bucket" "dataflow_bucket" {
  name          = "${var.project_id}-dataflow"
  location      = var.region
  project       = var.project_id
  force_destroy = false

  # No versioning
  versioning {
    enabled = false
  }

  # Set lifecycle rules to manage costs
  lifecycle_rule {
    condition {
      age = 7
    }
    action {
      type = "Delete"
    }
  }

  # Additional lifecycle rule for incomplete multipart uploads
  lifecycle_rule {
    condition {
      age = 1
    }
    action {
      type = "AbortIncompleteMultipartUpload"
    }
  }

  # Uniform bucket-level access
  uniform_bucket_level_access = true

  # Prevent public access
  public_access_prevention = "enforced"

  # Disable soft delete policy
  soft_delete_policy {
    retention_duration_seconds = 0
  }
}

# Reference existing data bucket
data "google_storage_bucket" "data_bucket" {
  name = var.data_bucket_name
}
