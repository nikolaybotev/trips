#!/bin/bash -e
# Script to run the Dataflow job for converting trips to staypoints

# Configuration
PROJECT_ID="feelinsosweet"
REGION="us-east1"
WORKER_SERVICE_ACCOUNT="dataflow-worker@feelinsosweet.iam.gserviceaccount.com"
INPUT_FILE="gs://feelinsosweet-starburst/trips-iceberg/data/trip_start_time_hour=2025-08-12-1**"
OUTPUT_PREFIX="gs://feelinsosweet-starburst/staypoints-hive"
TEMP_LOCATION="gs://feelinsosweet-dataflow/temp"
STAGING_LOCATION="gs://feelinsosweet-dataflow/staging"
CONTAINER_IMAGE_URL="us-east1-docker.pkg.dev/feelinsosweet/trips-to-staypoints-dataflow/trips-to-staypoints-dataflow"

# Dataflow job options
RUNNER="DataflowRunner"  # Use DirectRunner for local testing

# Needed by DataflowRunner
export GOOGLE_CLOUD_PROJECT=$PROJECT_ID

echo "Starting Dataflow job..."
echo "Project: $PROJECT_ID"
echo "Region: $REGION"
echo "Input: $INPUT_FILE"
echo "Output: $OUTPUT_PREFIX"
echo

python trips_to_staypoints_dataflow.py \
    --input="$INPUT_FILE" \
    --output="$OUTPUT_PREFIX" \
    --output_format=hive \
    --project="$PROJECT_ID" \
    --region="$REGION" \
    --runner="$RUNNER" \
    --temp_location="$TEMP_LOCATION" \
    --staging_location="$STAGING_LOCATION" \
    --job_name="trips-to-staypoints-$(date +%Y%m%d-%H%M%S)" \
    --max_num_workers=10 \
    --machine_type=n1-standard-4 \
    --disk_size_gb=50 \
    --experiments=use_runner_v2 \
    --dataflow_service_options=enable_dynamic_thread_scaling \
    --service_account_email="$WORKER_SERVICE_ACCOUNT" \
    --sdk_container_image="$CONTAINER_IMAGE_URL:latest" \
    --dataflow_service_options=enable_image_streaming \
    --sdk_location=container

echo
echo "Dataflow job submitted!"
echo "Check the Dataflow console for job status:"
echo "https://console.cloud.google.com/dataflow/jobs?project=$PROJECT_ID"
