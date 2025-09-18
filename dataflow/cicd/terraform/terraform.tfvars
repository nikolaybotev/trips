# GCP Project Configuration
project_id = "feelinsosweet"
region     = "us-east1"

# Artifact Registry Configuration
artifact_registry_repository_name = "dataflow-job"

# Network Configuration
vpc_name   = "dataflow-vpc"
vpc_cidr   = "10.0.0.0/16"
subnet_name = "dataflow-subnet"
subnet_cidr = "10.0.0.0/24"

# Service Account Configuration
service_account_name = "dataflow-worker"

# Data Bucket Name (pre-existing)
data_bucket_name = "feelinsosweet-starburst"

# Terraform State Bucket
terraform_state_bucket = "feelinsosweet-terraform-state"
