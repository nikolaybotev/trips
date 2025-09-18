#!/bin/bash -e
# Script to run the Dataflow job using BigQuery as source

# Load configuration
source ./config.sh

# BigQuery configuration
INPUT_TABLE="${PROJECT_ID}.trips_data.trips"  # Your BigQuery trips table
OUTPUT_TABLE="${PROJECT_ID}.trips_data.staypoints"  # Output table for staypoints
TEMP_LOCATION="gs://${PROJECT_ID}-dataflow/temp"
STAGING_LOCATION="gs://${PROJECT_ID}-dataflow/staging"
CONTAINER_IMAGE_URL="${REGION}-docker.pkg.dev/${PROJECT_ID}/${ARTIFACT_REGISTRY_REPOSITORY_NAME}/${DOCKER_IMAGE_NAME}"
SUBNETWORK_URL="https://www.googleapis.com/compute/v1/projects/${PROJECT_ID}/regions/${REGION}/subnetworks/${SUBNET_NAME}"

# Job-specific configuration
JOB_NAME="trips-to-staypoints-bigquery-$(date +%Y%m%d-%H%M%S)"

echo "Starting BigQuery Dataflow job..."
echo "Project: $PROJECT_ID"
echo "Region: $REGION"
echo "Job name: $JOB_NAME"
echo "Input table: $INPUT_TABLE"
echo "Output table: $OUTPUT_TABLE"
echo

# Start the Dataflow job with BigQuery integration
export GOOGLE_CLOUD_PROJECT="$PROJECT_ID"
python trips_to_staypoints/main_bigquery.py \
    --input_table="$INPUT_TABLE" \
    --output_table="$OUTPUT_TABLE" \
    --output_format=bigquery \
    --project="$PROJECT_ID" \
    --region="$REGION" \
    --runner="DataflowRunner" \
    --temp_location="$TEMP_LOCATION" \
    --staging_location="$STAGING_LOCATION" \
    --service_account_email="${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --job_name="$JOB_NAME" \
    --dataflow_service_options=min_num_workers=1 \
    --max_num_workers=18 \
    --disk_size_gb=25 \
    --worker_disk_type=compute.googleapis.com/projects/$PROJECT_ID/zones/$REGION/diskTypes/pd-ssd \
    --experiments=use_runner_v2 \
    --dataflow_service_options=enable_prime \
    --dataflow_service_options=enable_dynamic_thread_scaling \
    --dataflow_service_options=enable_image_streaming \
    --sdk_container_image="$CONTAINER_IMAGE_URL:$VERSION" \
    --sdk_location=container \
    --no_use_public_ips \
    --subnetwork=$SUBNETWORK_URL

echo
echo "BigQuery Dataflow job submitted!"
echo "Check the Dataflow console for job status:"
echo "https://console.cloud.google.com/dataflow/jobs?project=$PROJECT_ID"
echo
echo "Check BigQuery for results:"
echo "https://console.cloud.google.com/bigquery?project=$PROJECT_ID"
