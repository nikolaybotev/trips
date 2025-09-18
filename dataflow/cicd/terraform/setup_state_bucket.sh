#!/bin/bash
# Script to create and configure GCS bucket for Terraform state storage

set -e

# Configuration
PROJECT_ID="${PROJECT_ID:-feelinsosweet}"
BUCKET_NAME="${BUCKET_NAME:-feelinsosweet-terraform-state}"
REGION="${REGION:-us-east1}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Terraform State Bucket Setup${NC}"
echo "================================"
echo "Project ID: $PROJECT_ID"
echo "Bucket Name: $BUCKET_NAME"
echo "Region: $REGION"
echo ""

# Check if gcloud is installed and authenticated
if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}Error: gcloud command not found. Please install Google Cloud SDK.${NC}"
    exit 1
fi

# Check if user is authenticated
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
    echo -e "${RED}Error: No active gcloud authentication found.${NC}"
    echo "Please run: gcloud auth login"
    exit 1
fi

# Set the project
echo -e "${YELLOW}Setting project to $PROJECT_ID...${NC}"
gcloud config set project $PROJECT_ID

# Check if bucket already exists
if gsutil ls -b gs://$BUCKET_NAME &>/dev/null; then
    echo -e "${YELLOW}Bucket $BUCKET_NAME already exists.${NC}"
    echo "Checking configuration..."
else
    echo -e "${YELLOW}Creating bucket $BUCKET_NAME...${NC}"

    # Create the bucket
    gsutil mb -p $PROJECT_ID -c STANDARD -l $REGION gs://$BUCKET_NAME

    echo -e "${GREEN}Bucket created successfully!${NC}"
fi

# Create a basic IAM policy for the bucket
echo -e "${YELLOW}Setting up IAM permissions...${NC}"

# Get current user email
CURRENT_USER=$(gcloud auth list --filter=status:ACTIVE --format="value(account)")

# Create IAM policy file
cat > iam-policy.json << EOF
{
  "bindings": [
    {
      "role": "roles/storage.admin",
      "members": [
        "user:$CURRENT_USER"
      ]
    }
  ]
}
EOF

# Apply IAM policy
gsutil iam set iam-policy.json gs://$BUCKET_NAME
rm iam-policy.json

# Enable versioning (required for state locking)
echo -e "${YELLOW}Enabling versioning on bucket...${NC}"
gsutil versioning set on gs://$BUCKET_NAME

# Set lifecycle policy to manage old versions
echo -e "${YELLOW}Setting lifecycle policy...${NC}"
cat > lifecycle.json << EOF
{
  "rule": [
    {
      "action": {
        "type": "Delete"
      },
      "condition": {
        "age": 7,
        "isLive": false
      }
    }
  ]
}
EOF

gsutil lifecycle set lifecycle.json gs://$BUCKET_NAME
rm lifecycle.json

# Set uniform bucket-level access (recommended for security)
echo -e "${YELLOW}Setting uniform bucket-level access...${NC}"
gsutil uniformbucketlevelaccess set on gs://$BUCKET_NAME

echo ""
echo -e "${GREEN}✅ Terraform state bucket setup completed successfully!${NC}"
echo ""
echo -e "${BLUE}Bucket Details:${NC}"
echo "  Name: $BUCKET_NAME"
echo "  Project: $PROJECT_ID"
echo "  Region: $REGION"
echo "  Versioning: Enabled"
echo "  Uniform Access: Enabled"
echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo "1. Initialize Terraform with the new backend:"
echo "   cd $(pwd)"
echo "   terraform init"
echo ""
echo "2. If you have existing state, migrate it:"
echo "   terraform init -migrate-state"
echo ""
echo "3. Verify the state is stored in GCS:"
echo "   terraform state list"
echo ""
echo -e "${YELLOW}Note: Make sure to commit your backend.tf file to version control.${NC}"
echo -e "${YELLOW}Other team members will need to run 'terraform init' to use the remote state.${NC}"
