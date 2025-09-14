# Create Artifact Registry repository
resource "google_artifact_registry_repository" "dataflow_repo" {
  location      = var.region
  repository_id = var.artifact_registry_repository_name
  description   = "Docker repository for trips to staypoints dataflow job"
  format        = "DOCKER"
  project       = var.project_id

  depends_on = [
    google_project_service.artifactregistry
  ]
}

# Allow Dataflow worker account to read from Artifact Registry
resource "google_artifact_registry_repository_iam_member" "dataflow_reader" {
  location   = google_artifact_registry_repository.dataflow_repo.location
  repository = google_artifact_registry_repository.dataflow_repo.name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${google_service_account.dataflow_worker.email}"

  depends_on = [
    google_service_account.dataflow_worker,
    google_artifact_registry_repository.dataflow_repo
  ]
}
