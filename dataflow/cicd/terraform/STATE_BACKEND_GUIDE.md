# Terraform State Backend Guide

This guide explains how to use the GCS backend for Terraform state storage in this project.

## Overview

The Terraform configuration now uses Google Cloud Storage (GCS) as the backend for storing state files. This provides better collaboration, security, and state management.

## State Backend Configuration

### Backend Configuration (`backend.tf`)
```hcl
terraform {
  backend "gcs" {
    bucket = "feelinsosweet-terraform-state"
    prefix = "trips-dataflow-infrastructure"
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}
```

### State Location
- **Bucket**: `feelinsosweet-terraform-state`
- **Path**: `trips-dataflow-infrastructure/terraform.tfstate`
- **Full Path**: `gs://feelinsosweet-terraform-state/trips-dataflow-infrastructure/terraform.tfstate`

## Setup Instructions

### 1. First Time Setup (New Installation)

```bash
# 1. Create the state bucket
./setup_state_bucket.sh

# 2. Initialize Terraform
terraform init

# 3. Plan and apply
terraform plan
terraform apply
```

### 2. Migrating Existing State

If you have existing local state files:

```bash
# 1. Create the state bucket
./setup_state_bucket.sh

# 2. Migrate existing state
./migrate_to_remote_state.sh

# 3. Verify migration
terraform state list
```

### 3. Team Member Setup

For team members joining the project:

```bash
# 1. Clone the repository
git clone <repository-url>
cd dataflow/cicd/terraform

# 2. Initialize Terraform (will use remote state)
terraform init

# 3. Verify access
terraform state list
```

## State Bucket Features

The state bucket is configured with:

- **Versioning**: Enabled for state file history
- **Lifecycle Management**: Old versions deleted after 90 days
- **Uniform Access**: Consistent IAM policies
- **Encryption**: Default GCS encryption
- **Access Logging**: Audit trail for state access

## Benefits of GCS Backend

### 1. Team Collaboration
- Multiple developers can work on the same infrastructure
- No state file conflicts
- Centralized state management

### 2. Security
- State files stored securely in GCS
- IAM-based access control
- Audit logging

### 3. Reliability
- State locking prevents concurrent modifications
- Versioning provides rollback capabilities
- High availability and durability

### 4. Cost Effective
- Minimal storage costs
- No additional infrastructure required
- Pay only for what you use

## State Management Commands

### View State
```bash
# List all resources in state
terraform state list

# Show specific resource
terraform state show <resource_name>

# Show state file contents
terraform state pull
```

### Modify State
```bash
# Import existing resource
terraform import <resource_type>.<resource_name> <resource_id>

# Remove resource from state
terraform state rm <resource_name>

# Move resource in state
terraform state mv <old_name> <new_name>
```

### State Backup
```bash
# Download current state
terraform state pull > state-backup.json

# Restore state (if needed)
terraform state push state-backup.json
```

## Troubleshooting

### Common Issues

1. **Bucket Not Found**
   ```bash
   # Create the bucket
   ./setup_state_bucket.sh
   ```

2. **Permission Denied**
   ```bash
   # Check authentication
   gcloud auth list

   # Re-authenticate if needed
   gcloud auth application-default login
   ```

3. **State Lock Issues**
   ```bash
   # Force unlock (use with caution)
   terraform force-unlock <lock_id>
   ```

4. **State Migration Failed**
   ```bash
   # Check for existing state
   ls -la terraform.tfstate*

   # Re-run migration
   ./migrate_to_remote_state.sh
   ```

### State File Location

- **Local**: `terraform.tfstate` (backup only after migration)
- **Remote**: `gs://feelinsosweet-terraform-state/trips-dataflow-infrastructure/terraform.tfstate`

## Security Best Practices

1. **Access Control**
   - Use IAM roles for state bucket access
   - Limit access to necessary team members
   - Use service accounts for CI/CD

2. **State File Security**
   - Never commit state files to version control
   - Use encryption at rest (enabled by default)
   - Enable audit logging

3. **Backup Strategy**
   - Regular state backups
   - Test restore procedures
   - Monitor state file changes

## Monitoring and Alerts

### State File Monitoring
```bash
# Check state file size
gsutil du -s gs://feelinsosweet-terraform-state/trips-dataflow-infrastructure/

# List state file versions
gsutil ls -la gs://feelinsosweet-terraform-state/trips-dataflow-infrastructure/
```

### Access Logging
- State file access is logged in Cloud Audit Logs
- Monitor for unauthorized access
- Set up alerts for state modifications

## Cost Optimization

### Storage Costs
- State files are typically small (< 1MB)
- Minimal storage costs
- Lifecycle policies clean up old versions

### Network Costs
- State operations are minimal
- No significant network costs
- Consider region for data residency

## Migration Checklist

- [ ] Create state bucket
- [ ] Configure backend.tf
- [ ] Initialize Terraform
- [ ] Migrate existing state (if applicable)
- [ ] Verify state access
- [ ] Test plan/apply operations
- [ ] Update team documentation
- [ ] Remove local state files (after verification)

## Support

For issues with state backend:

1. Check authentication: `gcloud auth list`
2. Verify bucket exists: `gsutil ls gs://feelinsosweet-terraform-state`
3. Check permissions: `gsutil iam get gs://feelinsosweet-terraform-state`
4. Review Terraform logs: `TF_LOG=DEBUG terraform init`
5. Check state file: `terraform state list`
