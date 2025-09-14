#!/bin/bash -e

PROJECT_ID="feelinsosweet"
REGION="us-east1"
ARTIFACT_REGISTRY_REPOSITORY_NAME="trips-to-staypoints-dataflow"
ARTIFACT_REGISTRY_URL="us-east1-docker.pkg.dev/$PROJECT_ID/$ARTIFACT_REGISTRY_REPOSITORY_NAME"

# Enable required Google Cloud APIs
echo "Enabling required Google Cloud APIs..."

gcloud services enable dataflow.googleapis.com --project=$PROJECT_ID
gcloud services enable compute.googleapis.com --project=$PROJECT_ID
gcloud services enable storage-component.googleapis.com --project=$PROJECT_ID
gcloud services enable artifactregistry.googleapis.com --project=$PROJECT_ID
gcloud services enable containerfilesystem.googleapis.com --project=$PROJECT_ID
gcloud services enable logging.googleapis.com --project=$PROJECT_ID
gcloud services enable monitoring.googleapis.com --project=$PROJECT_ID

echo "APIs enabled successfully!"
echo

# Create subnet for Dataflow jobs with Private Google Access
echo "Creating subnet for Dataflow jobs..."

SUBNET_NAME="dataflow-subnet"
SUBNET_CIDR="10.0.0.0/24"

# Get the default VPC network name
DEFAULT_VPC=$(gcloud compute networks list --filter="name:default" --format="value(name)" --project=$PROJECT_ID)

if [ -z "$DEFAULT_VPC" ]; then
  echo "Error: Default VPC network not found in project $PROJECT_ID"
  exit 1
fi

echo "Using default VPC: $DEFAULT_VPC"

# Create the subnet with Private Google Access enabled
gcloud compute networks subnets create $SUBNET_NAME \
  --network=$DEFAULT_VPC \
  --range=$SUBNET_CIDR \
  --region=$REGION \
  --enable-private-ip-google-access \
  --project=$PROJECT_ID

echo "Subnet $SUBNET_NAME created successfully with Private Google Access!"
echo

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
#docker buildx create --driver=docker-container --use
