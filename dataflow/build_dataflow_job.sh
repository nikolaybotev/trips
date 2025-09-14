#!/bin/bash -e
# Script to build the Dataflow job Docker image

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

# Image namd and URL
IMAGE_NAME="trips-to-staypoints-dataflow"
ARTIFACT_REGISTRY_URL="$REGION-docker.pkg.dev/$PROJECT_ID/$ARTIFACT_REGISTRY_REPOSITORY_NAME/$IMAGE_NAME"

# Image version
VERSION="${1:-latest}"

echo
echo "Configuration:"
echo "  - project: $PROJECT_ID"
echo "  - region: $REGION"
echo "  - artifact registry repository: $ARTIFACT_REGISTRY_REPOSITORY_NAME"
echo

echo
echo "Building Docker image..."
echo "  $IMAGE_NAME:$VERSION"
echo

# Build the Docker image locally first (no push)
docker buildx build \
  --platform=linux/amd64,linux/arm64 \
  --no-cache \
  -t $IMAGE_NAME:$VERSION \
  --load \
  .

# Tag the Docker image for Google Artifact Registry
docker tag $IMAGE_NAME:$VERSION $ARTIFACT_REGISTRY_URL:$VERSION

echo
echo "Docker image built and tagged:"
echo "  $IMAGE_NAME:$VERSION"
echo

echo
echo "Pushing to Google Artifact Registry..."
echo "  $ARTIFACT_REGISTRY_URL:$VERSION"
echo

# Configure Docker to use gcloud as a credential helper for Artifact Registry
gcloud auth configure-docker us-east1-docker.pkg.dev

# Push the Docker image to Google Artifact Registry using regular docker push
docker push $ARTIFACT_REGISTRY_URL:$VERSION

echo
echo "Docker image pushed to Google Artifact Registry:"
echo "  $ARTIFACT_REGISTRY_URL:$VERSION"
echo
echo "Done!"
echo
