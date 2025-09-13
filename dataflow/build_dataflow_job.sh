#!/bin/bash -e
# Script to build the Dataflow job Docker image

# Configuration
PROJECT_ID="feelinsosweet"
REGION="us-east1"
ARTIFACT_REGISTRY_HOSTNAME="us-east1-docker.pkg.dev"
ARTIFACT_REGISTRY_REPOSITORY_NAME="trips-to-staypoints-dataflow"
IMAGE_NAME="trips-to-staypoints-dataflow"
ARTIFACT_REGISTRY_URL="$ARTIFACT_REGISTRY_HOSTNAME/$PROJECT_ID/$ARTIFACT_REGISTRY_REPOSITORY_NAME/$IMAGE_NAME"

VERSION="latest"

echo
echo "Building Docker image..."
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
echo "  $ARTIFACT_REGISTRY_URL:$VERSION"
echo
echo "Pushing to Google Artifact Registry..."
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
