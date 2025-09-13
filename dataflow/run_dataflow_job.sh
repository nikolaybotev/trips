#!/bin/bash
# Script to run the Dataflow job for converting trips to staypoints

# Configuration
PROJECT_ID="feelinsosweet"
REGION="us-east1"
INPUT_FILE="gs://feelinsosweet-starburst/trips-iceberg/data/**"
OUTPUT_PREFIX="gs://feelinsosweet-starburst/staypoints-hive"
TEMP_LOCATION="gs://feelinsosweet-starburst/dataflow/temp"
STAGING_LOCATION="gs://feelinsosweet-starburst/dataflow/staging"

# Dataflow job options
RUNNER="DataflowRunner"  # Use DirectRunner for local testing

echo "Starting Dataflow job..."
echo "Project: $PROJECT_ID"
echo "Region: $REGION"
echo "Input: $INPUT_FILE"
echo "Output: $OUTPUT_PREFIX"

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
    --experiments=use_runner_v2

echo "Dataflow job submitted!"
echo "Check the Dataflow console for job status:"
echo "https://console.cloud.google.com/dataflow/jobs?project=$PROJECT_ID"
