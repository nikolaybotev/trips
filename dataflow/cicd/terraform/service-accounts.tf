# Create Dataflow worker service account
resource "google_service_account" "dataflow_worker" {
  account_id   = var.service_account_name
  display_name = "Dataflow worker service account"
  project      = var.project_id

  depends_on = [
    google_project_service.compute
  ]
}

# IAM bindings for Dataflow worker service account
resource "google_project_iam_member" "dataflow_viewer" {
  project = var.project_id
  role    = "roles/dataflow.viewer"
  member  = "serviceAccount:${google_service_account.dataflow_worker.email}"

  depends_on = [
    google_service_account.dataflow_worker,
    google_project_service.dataflow
  ]
}

resource "google_project_iam_member" "dataflow_worker" {
  project = var.project_id
  role    = "roles/dataflow.worker"
  member  = "serviceAccount:${google_service_account.dataflow_worker.email}"

  depends_on = [
    google_service_account.dataflow_worker,
    google_project_service.dataflow
  ]
}

resource "google_project_iam_member" "storage_object_user" {
  project = var.project_id
  role    = "roles/storage.objectUser"
  member  = "serviceAccount:${google_service_account.dataflow_worker.email}"

  depends_on = [
    google_service_account.dataflow_worker,
    google_project_service.storage
  ]
}

resource "google_storage_bucket_iam_member" "data_bucket_object_user" {
  bucket = data.google_storage_bucket.data_bucket.name
  role   = "roles/storage.objectUser"
  member = "serviceAccount:${google_service_account.dataflow_worker.email}"

  depends_on = [
    google_project_service.storage
  ]
}
