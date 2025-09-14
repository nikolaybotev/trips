# Enable required Google Cloud APIs
resource "google_project_service" "dataflow" {
  project = var.project_id
  service = "dataflow.googleapis.com"
}

resource "google_project_service" "artifactregistry" {
  project = var.project_id
  service = "artifactregistry.googleapis.com"
}

resource "google_project_service" "containerfilesystem" {
  project = var.project_id
  service = "containerfilesystem.googleapis.com"
}
