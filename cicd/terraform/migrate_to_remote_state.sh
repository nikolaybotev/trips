#!/bin/bash
# Script to migrate existing Terraform state to GCS backend

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Terraform State Migration to GCS${NC}"
echo "===================================="
echo ""

# Check if terraform is installed
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}Error: terraform command not found. Please install Terraform.${NC}"
    exit 1
fi

# Check if we're in a terraform directory
if [ ! -f "backend.tf" ]; then
    echo -e "${RED}Error: backend.tf not found. Please run this script from the terraform directory.${NC}"
    exit 1
fi

# Check if terraform state exists locally
if [ ! -f "terraform.tfstate" ] && [ ! -f "terraform.tfstate.backup" ]; then
    echo -e "${YELLOW}No local state files found. Initializing with remote backend...${NC}"
    terraform init
    echo -e "${GREEN}✅ Initialization completed!${NC}"
    exit 0
fi

echo -e "${YELLOW}Found existing local state. Proceeding with migration...${NC}"
echo ""

# Step 1: Initialize with remote backend
echo -e "${BLUE}Step 1: Initializing with remote backend...${NC}"
terraform init

echo ""
echo -e "${YELLOW}Terraform will ask if you want to migrate existing state to the new backend.${NC}"
echo -e "${YELLOW}Type 'yes' when prompted.${NC}"
echo ""

# Step 2: Migrate state
echo -e "${BLUE}Step 2: Migrating state to remote backend...${NC}"
terraform init -migrate-state

echo ""
echo -e "${BLUE}Step 3: Verifying migration...${NC}"

# Step 3: Verify the migration
if terraform state list > /dev/null 2>&1; then
    echo -e "${GREEN}✅ State migration successful!${NC}"
    echo ""
    echo -e "${BLUE}Current state resources:${NC}"
    terraform state list
    echo ""
    echo -e "${GREEN}✅ Migration completed successfully!${NC}"
    echo ""
    echo -e "${BLUE}Next Steps:${NC}"
    echo "1. Verify your infrastructure: terraform plan"
    echo "2. Commit your changes to version control"
    echo "3. Share the backend.tf file with your team"
    echo "4. Team members should run 'terraform init' to use remote state"
    echo ""
    echo -e "${YELLOW}Note: Your local state files (terraform.tfstate*) are now backed up.${NC}"
    echo -e "${YELLOW}You can safely delete them after verifying everything works correctly.${NC}"
else
    echo -e "${RED}❌ State migration failed!${NC}"
    echo "Please check the error messages above and try again."
    exit 1
fi
