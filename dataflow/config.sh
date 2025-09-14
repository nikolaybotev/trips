#!/bin/bash
# Configuration loader for Dataflow scripts
# Loads configuration from terraform.tfvars

# Load configuration from terraform.tfvars
TERRAFORM_TFVARS="./cicd/terraform/terraform.tfvars"

# Function to extract values from terraform.tfvars
extract_tfvars_value() {
    local key="$1"
    grep "^${key}" "$TERRAFORM_TFVARS" | sed 's/.*= *"\(.*\)".*/\1/' | tr -d ' '
}

# Configuration from terraform.tfvars
PROJECT_ID=$(extract_tfvars_value "project_id")
REGION=$(extract_tfvars_value "region")
ARTIFACT_REGISTRY_REPOSITORY_NAME=$(extract_tfvars_value "artifact_registry_repository_name")
SUBNET_NAME=$(extract_tfvars_value "subnet_name")
SERVICE_ACCOUNT_NAME=$(extract_tfvars_value "service_account_name")
DATA_BUCKET_NAME=$(extract_tfvars_value "data_bucket_name")

# Image name
DOCKER_IMAGE_NAME="trips-to-staypoints"

# Image URL
CONTAINER_IMAGE_URL="$REGION-docker.pkg.dev/$PROJECT_ID/$ARTIFACT_REGISTRY_REPOSITORY_NAME/$DOCKER_IMAGE_NAME"

# Image version
VERSION="${1:-latest}"

# Display configuration
echo "Configuration loaded:"
echo "  - project: $PROJECT_ID"
echo "  - region: $REGION"
echo "  - artifact registry repository: $ARTIFACT_REGISTRY_REPOSITORY_NAME"
echo "  - subnet: $SUBNET_NAME"
echo "  - service account: $SERVICE_ACCOUNT_NAME"
echo
