# Get the default VPC network
data "google_compute_network" "default" {
  name    = "default"
  project = var.project_id
}

# Create subnet for Dataflow jobs with Private Google Access
resource "google_compute_subnetwork" "dataflow_subnet" {
  name          = var.subnet_name
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = data.google_compute_network.default.id
  project       = var.project_id

  private_ip_google_access = true

  depends_on = [
    google_project_service.compute
  ]
}
