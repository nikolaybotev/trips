# Outputs
output "project_id" {
  description = "The GCP project ID"
  value       = var.project_id
}

output "region" {
  description = "The GCP region"
  value       = var.region
}

output "artifact_registry_url" {
  description = "The Artifact Registry URL"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.dataflow_repo.name}"
}

output "subnet_name" {
  description = "The Dataflow subnet name"
  value       = google_compute_subnetwork.dataflow_subnet.name
}

output "subnet_cidr" {
  description = "The Dataflow subnet CIDR"
  value       = google_compute_subnetwork.dataflow_subnet.ip_cidr_range
}

output "service_account_email" {
  description = "The Dataflow worker service account email"
  value       = google_service_account.dataflow_worker.email
}

output "artifact_registry_repository_name" {
  description = "The Artifact Registry repository name"
  value       = google_artifact_registry_repository.dataflow_repo.name
}

output "dataflow_bucket_name" {
  description = "The GCS bucket name for Dataflow temporary and staging files"
  value       = google_storage_bucket.dataflow_bucket.name
}

output "dataflow_bucket_url" {
  description = "The GCS bucket URL for Dataflow temporary and staging files"
  value       = google_storage_bucket.dataflow_bucket.url
}

output "dataflow_temp_location" {
  description = "The GCS path for Dataflow temporary files"
  value       = "gs://${google_storage_bucket.dataflow_bucket.name}/temp"
}

output "dataflow_staging_location" {
  description = "The GCS path for Dataflow staging files"
  value       = "gs://${google_storage_bucket.dataflow_bucket.name}/staging"
}
