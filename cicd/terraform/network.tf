# Create dedicated VPC for Dataflow jobs (completely isolated)
resource "google_compute_network" "dataflow_vpc" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
  project                 = var.project_id

  # Ensure complete isolation - no external connectivity
  description = "Dedicated VPC for Dataflow jobs - completely isolated"
}

# Create subnet for Dataflow jobs with Private Google Access
resource "google_compute_subnetwork" "dataflow_subnet" {
  name          = var.subnet_name
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.dataflow_vpc.id
  project       = var.project_id

  # Enable private access to Google APIs (required for Dataflow)
  private_ip_google_access = true

  description = "Isolated subnet for Dataflow jobs with private Google access only"
}
