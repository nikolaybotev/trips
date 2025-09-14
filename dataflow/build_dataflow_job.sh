#!/bin/bash -e
# Script to build the Dataflow job Docker image

# Load configuration
source ./config.sh

echo
echo "Building Docker image..."
echo "  $DOCKER_IMAGE_NAME:$VERSION"
echo

# Build the Docker image locally first (no push)
docker buildx build \
  --platform=linux/amd64,linux/arm64 \
  --no-cache \
  -t $DOCKER_IMAGE_NAME:$VERSION \
  --load \
  .

# Tag the Docker image for Google Artifact Registry
docker tag $DOCKER_IMAGE_NAME:$VERSION $CONTAINER_IMAGE_URL:$VERSION

echo
echo "Docker image built and tagged:"
echo "  $DOCKER_IMAGE_NAME:$VERSION"
echo

echo
echo "Pushing to Google Artifact Registry..."
echo "  $CONTAINER_IMAGE_URL:$VERSION"
echo

# Configure Docker to use gcloud as a credential helper for Artifact Registry
gcloud auth configure-docker us-east1-docker.pkg.dev

# Push the Docker image to Google Artifact Registry using regular docker push
docker push $CONTAINER_IMAGE_URL:$VERSION

echo
echo "Docker image pushed to Google Artifact Registry:"
echo "  $CONTAINER_IMAGE_URL:$VERSION"
echo
echo "Done!"
echo
