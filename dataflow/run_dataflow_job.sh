#!/bin/bash -e
# Script to run the Dataflow job for converting trips to staypoints

# Load configuration
source ./config.sh

# Job-specific configuration
JOB_NAME="trips-to-staypoints-$(date +%Y%m%d-%H%M%S)"

echo "Starting Dataflow job..."
echo "Project: $PROJECT_ID"
echo "Region: $REGION"
echo "Job name: $JOB_NAME"
echo "Input: $INPUT_FILES"
echo "Output: $OUTPUT_PREFIX"
echo

# Start the Dataflow job with the following pipeline options:
# See https://cloud.google.com/dataflow/docs/reference/pipeline-options#pythonyaml_3
export GOOGLE_CLOUD_PROJECT="$PROJECT_ID" # Needed by DataflowRunner
python trips_to_staypoints/main.py \
    --input="$INPUT_FILES" \
    --output="$OUTPUT_PREFIX" \
    --output_format=hive \
    --project="$PROJECT_ID" \
    --region="$REGION" \
    --runner="DataflowRunner" \
    --temp_location="$TEMP_LOCATION" \
    --staging_location="$STAGING_LOCATION" \
    --service_account_email="$WORKER_SERVICE_ACCOUNT" \
    --job_name="$JOB_NAME" \
    --dataflow_service_options=min_num_workers=18 \
    --max_num_workers=18 \
    --disk_size_gb=25 \
    --worker_disk_type=compute.googleapis.com/projects/$PROJECT_ID/zones/$REGION/diskTypes/pd-ssd \
    --experiments=use_runner_v2 \
    --dataflow_service_options=enable_prime \
    --dataflow_service_options=enable_dynamic_thread_scaling \
    --dataflow_service_options=enable_image_streaming \
    --sdk_container_image="$CONTAINER_IMAGE_URL:latest" \
    --sdk_location=container \
    --no_use_public_ips \
    --subnetwork=$SUBNETWORK_URL

echo
echo "Dataflow job submitted!"
echo "Check the Dataflow console for job status:"
echo "https://console.cloud.google.com/dataflow/jobs?project=$PROJECT_ID"
