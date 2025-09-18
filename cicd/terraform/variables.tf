variable "project_id" {
  description = "The GCP project ID"
  type        = string
  default     = "feelinsosweet"
}

variable "region" {
  description = "The GCP region"
  type        = string
  default     = "us-east1"
}

variable "artifact_registry_repository_name" {
  description = "Name for the Artifact Registry repository"
  type        = string
  default     = "dataflow-job"
}

variable "subnet_name" {
  description = "Name for the Dataflow subnet"
  type        = string
  default     = "dataflow-subnet"
}

variable "subnet_cidr" {
  description = "CIDR block for the Dataflow subnet"
  type        = string
  default     = "10.0.0.0/24"
}

variable "service_account_name" {
  description = "Name for the Dataflow worker service account"
  type        = string
  default     = "dataflow-worker"
}

variable "data_bucket_name" {
  description = "Name of pre-existing Data GCS bucket"
  type        = string
  default     = "feelinsosweet-starburst"
}

variable "vpc_name" {
  description = "Name for the dedicated Dataflow VPC"
  type        = string
  default     = "dataflow-vpc"
}

variable "vpc_cidr" {
  description = "CIDR block for the dedicated Dataflow VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "terraform_state_bucket" {
  description = "GCS bucket name for storing Terraform state"
  type        = string
  default     = "feelinsosweet-terraform-state"
}
