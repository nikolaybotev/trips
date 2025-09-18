terraform {
  # Backend configuration for GCS state storage
  backend "gcs" {
    # Bucket name for storing Terraform state
    # This bucket must exist before running terraform init
    bucket = "feelinsosweet-terraform-state"

    # Path within the bucket to store the state file
    # Using a descriptive path to organize state files
    prefix = "trips-dataflow-infrastructure"

    # Optional: Enable state locking (recommended for team environments)
    # This requires the bucket to have versioning enabled
    # Uncomment the line below if you want to enable state locking
    # enable_state_locking = true
  }

  # Required Terraform version
  required_version = ">= 1.0"

  # Required providers and their versions
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}
