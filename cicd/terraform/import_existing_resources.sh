#!/bin/bash
# Script to import existing GCP resources into Terraform state

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Terraform Resource Import Script${NC}"
echo "===================================="
echo ""

# Check if we're in a terraform directory
if [ ! -f "backend.tf" ]; then
    echo -e "${RED}Error: backend.tf not found. Please run this script from the terraform directory.${NC}"
    exit 1
fi

# Check if terraform is installed
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}Error: terraform command not found. Please install Terraform.${NC}"
    exit 1
fi

# Check if gcloud is installed and authenticated
if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}Error: gcloud command not found. Please install Google Cloud SDK.${NC}"
    exit 1
fi

# Get current project
PROJECT_ID=$(gcloud config get-value project)
echo -e "${BLUE}Current GCP Project: $PROJECT_ID${NC}"
echo ""

# Function to check if resource exists and import it
import_if_exists() {
    local resource_type="$1"
    local resource_name="$2"
    local gcp_resource_id="$3"
    local terraform_address="$4"

    echo -e "${YELLOW}Checking $resource_type: $resource_name${NC}"

    # Check if resource exists in GCP
    if gcloud services list --enabled --filter="name:$gcp_resource_id" --format="value(name)" | grep -q "$gcp_resource_id"; then
        echo -e "${GREEN}✓ Found existing $resource_type: $resource_name${NC}"

        # Import the resource
        echo -e "${YELLOW}Importing $terraform_address...${NC}"
        if terraform import "$terraform_address" "$PROJECT_ID/$gcp_resource_id"; then
            echo -e "${GREEN}✓ Successfully imported $terraform_address${NC}"
        else
            echo -e "${RED}✗ Failed to import $terraform_address${NC}"
        fi
    else
        echo -e "${YELLOW}○ $resource_type $resource_name does not exist, will be created${NC}"
    fi
    echo ""
}

# Import APIs that are already enabled
echo -e "${BLUE}Step 1: Importing enabled APIs${NC}"
echo "================================"

import_if_exists "API" "Artifact Registry" "artifactregistry.googleapis.com" "google_project_service.artifactregistry"
import_if_exists "API" "Compute Engine" "compute.googleapis.com" "google_project_service.compute"
import_if_exists "API" "Container File System" "containerfilesystem.googleapis.com" "google_project_service.containerfilesystem"
import_if_exists "API" "Dataflow" "dataflow.googleapis.com" "google_project_service.dataflow"
import_if_exists "API" "Logging" "logging.googleapis.com" "google_project_service.logging"
import_if_exists "API" "Monitoring" "monitoring.googleapis.com" "google_project_service.monitoring"
import_if_exists "API" "Storage" "storage-component.googleapis.com" "google_project_service.storage"

echo -e "${BLUE}Step 2: Checking other resources${NC}"
echo "=============================="

# Check for existing service accounts
echo -e "${YELLOW}Checking Service Accounts...${NC}"
if gcloud iam service-accounts list --filter="email:dataflow-worker@$PROJECT_ID.iam.gserviceaccount.com" --format="value(email)" | grep -q "dataflow-worker@$PROJECT_ID.iam.gserviceaccount.com"; then
    echo -e "${GREEN}✓ Found existing service account: dataflow-worker${NC}"
    echo -e "${YELLOW}Importing google_service_account.dataflow_worker...${NC}"
    if terraform import "google_service_account.dataflow_worker" "projects/$PROJECT_ID/serviceAccounts/dataflow-worker@$PROJECT_ID.iam.gserviceaccount.com"; then
        echo -e "${GREEN}✓ Successfully imported service account${NC}"
    else
        echo -e "${RED}✗ Failed to import service account${NC}"
    fi
else
    echo -e "${YELLOW}○ Service account dataflow-worker does not exist, will be created${NC}"
fi
echo ""

# Check for existing storage buckets
echo -e "${YELLOW}Checking Storage Buckets...${NC}"
if gsutil ls -b gs://feelinsosweet-dataflow &>/dev/null; then
    echo -e "${GREEN}✓ Found existing bucket: feelinsosweet-dataflow${NC}"
    echo -e "${YELLOW}Importing google_storage_bucket.dataflow_bucket...${NC}"
    if terraform import "google_storage_bucket.dataflow_bucket" "feelinsosweet-dataflow"; then
        echo -e "${GREEN}✓ Successfully imported storage bucket${NC}"
    else
        echo -e "${RED}✗ Failed to import storage bucket${NC}"
    fi
else
    echo -e "${YELLOW}○ Storage bucket feelinsosweet-dataflow does not exist, will be created${NC}"
fi
echo ""

# Check for existing VPC networks
echo -e "${YELLOW}Checking VPC Networks...${NC}"
if gcloud compute networks list --filter="name:dataflow-vpc" --format="value(name)" | grep -q "dataflow-vpc"; then
    echo -e "${GREEN}✓ Found existing VPC: dataflow-vpc${NC}"
    echo -e "${YELLOW}Importing google_compute_network.dataflow_vpc...${NC}"
    if terraform import "google_compute_network.dataflow_vpc" "projects/$PROJECT_ID/global/networks/dataflow-vpc"; then
        echo -e "${GREEN}✓ Successfully imported VPC network${NC}"
    else
        echo -e "${RED}✗ Failed to import VPC network${NC}"
    fi
else
    echo -e "${YELLOW}○ VPC network dataflow-vpc does not exist, will be created${NC}"
fi
echo ""

# Check for existing subnets
echo -e "${YELLOW}Checking Subnets...${NC}"
if gcloud compute networks subnets list --filter="name:dataflow-subnet" --format="value(name)" | grep -q "dataflow-subnet"; then
    echo -e "${GREEN}✓ Found existing subnet: dataflow-subnet${NC}"
    echo -e "${YELLOW}Importing google_compute_subnetwork.dataflow_subnet...${NC}"
    if terraform import "google_compute_subnetwork.dataflow_subnet" "projects/$PROJECT_ID/regions/us-east1/subnetworks/dataflow-subnet"; then
        echo -e "${GREEN}✓ Successfully imported subnet${NC}"
    else
        echo -e "${RED}✗ Failed to import subnet${NC}"
    fi
else
    echo -e "${YELLOW}○ Subnet dataflow-subnet does not exist, will be created${NC}"
fi
echo ""

# Check for existing Artifact Registry repositories
echo -e "${YELLOW}Checking Artifact Registry...${NC}"
if gcloud artifacts repositories list --location=us-east1 --filter="name:dataflow-job" --format="value(name)" | grep -q "dataflow-job"; then
    echo -e "${GREEN}✓ Found existing Artifact Registry repository: dataflow-job${NC}"
    echo -e "${YELLOW}Importing google_artifact_registry_repository.dataflow_repo...${NC}"
    if terraform import "google_artifact_registry_repository.dataflow_repo" "projects/$PROJECT_ID/locations/us-east1/repositories/dataflow-job"; then
        echo -e "${GREEN}✓ Successfully imported Artifact Registry repository${NC}"
    else
        echo -e "${RED}✗ Failed to import Artifact Registry repository${NC}"
    fi
else
    echo -e "${YELLOW}○ Artifact Registry repository dataflow-job does not exist, will be created${NC}"
fi
echo ""

echo -e "${BLUE}Step 3: Verifying imports${NC}"
echo "========================"

# Show current state
echo -e "${YELLOW}Current Terraform state:${NC}"
terraform state list

echo ""
echo -e "${GREEN}✅ Import process completed!${NC}"
echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo "1. Review the imported resources: terraform state list"
echo "2. Run terraform plan to see what still needs to be created"
echo "3. Run terraform apply to create any missing resources"
echo ""
echo -e "${YELLOW}Note: Some resources may have dependencies that need to be created first.${NC}"
echo -e "${YELLOW}If you encounter import errors, you may need to create dependent resources first.${NC}"

