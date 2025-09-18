# Terraform Configuration for Dataflow Setup

This Terraform configuration replicates the infrastructure created by the `../../dataflow/setup_dataflow_job.sh` script for Google Cloud Dataflow jobs.

## Prerequisites

1. **Terraform installed**: Version 1.0 or higher
2. **Google Cloud SDK**: Authenticated with appropriate permissions
3. **GCP Project**: With billing enabled
4. **GCS State Bucket**: For storing Terraform state (created automatically)

## Authentication

Before running Terraform, authenticate with Google Cloud:

```bash
gcloud auth application-default login
```

Or set the `GOOGLE_APPLICATION_CREDENTIALS` environment variable to point to a service account key file.

## Usage

### First Time Setup

1. **Create the state bucket**:
   ```bash
   ./setup_state_bucket.sh
   ```

2. **Initialize Terraform** (if you have existing state):
   ```bash
   ./migrate_to_remote_state.sh
   ```

   Or for new installations:
   ```bash
   terraform init
   ```

3. **Review the plan**:
   ```bash
   terraform plan
   ```

4. **Apply the configuration**:
   ```bash
   terraform apply
   ```

### Regular Usage

1. **Review the plan**:
   ```bash
   terraform plan
   ```

2. **Apply the configuration**:
   ```bash
   terraform apply
   ```

3. **Destroy resources** (when no longer needed):
   ```bash
   terraform destroy
   ```

## State Backend Configuration

This Terraform configuration uses **Google Cloud Storage (GCS)** as the backend for storing Terraform state. This provides:

- **Team Collaboration**: Multiple team members can work on the same infrastructure
- **State Locking**: Prevents concurrent modifications
- **Versioning**: State file history and rollback capabilities
- **Security**: Centralized state management with proper access controls

### State Bucket Configuration

The state is stored in: `gs://feelinsosweet-terraform-state/trips-dataflow-infrastructure/`

To customize the state bucket, modify `backend.tf`:
```hcl
terraform {
  backend "gcs" {
    bucket = "your-custom-bucket-name"
    prefix = "trips-dataflow-infrastructure"
  }
}
```

## Configuration

The configuration can be customized by modifying `terraform.tfvars`:

- `project_id`: Your GCP project ID
- `region`: GCP region for resources
- `artifact_registry_repository_name`: Name for the Docker repository
- `subnet_name`: Name for the Dataflow subnet
- `subnet_cidr`: CIDR block for the subnet
- `service_account_name`: Name for the Dataflow worker service account
- `terraform_state_bucket`: GCS bucket name for Terraform state

## Resources Created

This Terraform configuration creates:

1. **APIs Enabled**:
   - Dataflow API
   - Compute Engine API
   - Storage API
   - Artifact Registry API
   - Container File System API
   - Logging API
   - Monitoring API

2. **Network**:
   - Subnet in the default VPC with Private Google Access enabled

3. **Service Account**:
   - `dataflow-worker` service account with appropriate IAM roles:
     - `roles/dataflow.viewer`
     - `roles/dataflow.worker`
     - `roles/storage.objectUser`

4. **Artifact Registry**:
   - Docker repository for storing Dataflow container images
   - IAM binding allowing the service account to read from the repository

5. **Storage**:
   - GCS bucket (`feelinsosweet-dataflow`) for Dataflow temporary and staging files
   - Lifecycle rules to manage costs (30-day retention, 7-day incomplete upload cleanup)
   - Versioning enabled for data protection
   - IAM binding allowing the service account full access to the bucket

## Outputs

After applying, Terraform will output:
- `artifact_registry_url`: Full URL for the Artifact Registry repository
- `service_account_email`: Email of the created service account
- `subnet_name`: Name of the created subnet
- `dataflow_bucket_name`: Name of the GCS bucket for Dataflow files
- `dataflow_temp_location`: GCS path for Dataflow temporary files
- `dataflow_staging_location`: GCS path for Dataflow staging files
- Other configuration values

## Migration from Shell Script

To migrate from using the shell script to Terraform:

1. **Backup existing resources**: If you have existing resources created by the shell script, consider their state
2. **Import existing resources** (optional): You can import existing resources into Terraform state using `terraform import`
3. **Apply Terraform**: Run `terraform apply` to ensure all resources match the desired state

## Directory Structure

This Terraform configuration is organized in the `cicd/terraform/` directory:

```
cicd/terraform/
├── backend.tf            # Terraform backend and provider configuration
├── providers.tf          # Provider configuration
├── variables.tf          # Variable definitions
├── terraform.tfvars      # Variable values
├── apis.tf              # Google Cloud API enablement
├── network.tf           # VPC and subnet configuration
├── service-accounts.tf  # Service accounts and IAM
├── artifact-registry.tf # Artifact Registry configuration
├── storage.tf           # GCS bucket for Dataflow temp/staging
├── outputs.tf           # Output definitions
└── README.md            # This documentation
```

## Notes

- The configuration assumes a default VPC network exists in your project
- All resources are created in the specified region
- The subnet uses Private Google Access for Dataflow worker nodes
- Dependencies are properly configured to ensure resources are created in the correct order
