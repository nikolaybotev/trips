#!/bin/bash -e

PROJECT_ID="feelinsosweet"
REGION="us-east1"
ARTIFACT_REGISTRY_REPOSITORY_NAME="trips-to-staypoints-dataflow"
ARTIFACT_REGISTRY_URL="us-east1-docker.pkg.dev/$PROJECT_ID/$ARTIFACT_REGISTRY_REPOSITORY_NAME"

# Create Dataflow worker service account

gcloud iam service-accounts create dataflow-worker \
  --display-name="Dataflow worker service account"

# Add IAM policies to Dataflow worker service account

gcloud iam service-accounts add-iam-policy-binding dataflow-worker@$PROJECT_ID.iam.gserviceaccount.com \
  --role=roles/dataflow.viewer \
  --member=serviceAccount:dataflow-worker@$PROJECT_ID.iam.gserviceaccount.com

gcloud iam service-accounts add-iam-policy-binding dataflow-worker@$PROJECT_ID.iam.gserviceaccount.com \
  --role=roles/dataflow.worker \
  --member=serviceAccount:dataflow-worker@$PROJECT_ID.iam.gserviceaccount.com

gcloud iam service-accounts add-iam-policy-binding dataflow-worker@$PROJECT_ID.iam.gserviceaccount.com \
  --role=roles/storage.objectUser \
  --member=serviceAccount:dataflow-worker@$PROJECT_ID.iam.gserviceaccount.com

# Create Artifact Registry repository

gcloud artifacts repositories create $ARTIFACT_REGISTRY_REPOSITORY_NAME \
  --repository-format=docker \
  --location=$REGION \
  --description="Docker repository for trips to staypoints dataflow job"

# Allow Dataflow service account to read from Artifact Registry
# See https://cloud.google.com/dataflow/docs/concepts/security-and-permissions#permissions

gcloud artifacts repositories add-iam-policy-binding $ARTIFACT_REGISTRY_REPOSITORY_NAME \
  --location=$REGION \
  --member=serviceAccount:dataflow-worker@$PROJECT_ID.iam.gserviceaccount.com \
  --role=roles/artifactregistry.reader

# Create a new builder
docker buildx create --driver=docker-container --use
