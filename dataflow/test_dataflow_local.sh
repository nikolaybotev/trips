#!/bin/bash
# Script to test the Dataflow job locally

# Configuration for local testing
INPUT_FILE="input/**"  # Local Parquet file
OUTPUT_PREFIX="output/"

echo "Testing Dataflow job locally..."
echo "Input: $INPUT_FILE"
echo "Output: $OUTPUT_PREFIX"
echo

# Create output directory if it doesn't exist
mkdir -p output

# Configure GRPC settings to prevent timeouts
export GRPC_MAX_MESSAGE_LENGTH=134217728  # 128MB
export GRPC_KEEPALIVE_TIME_MS=30000       # 30 seconds
export GRPC_KEEPALIVE_TIMEOUT_MS=5000     # 5 seconds
export GRPC_KEEPALIVE_PERMIT_WITHOUT_CALLS=true
export GRPC_HTTP2_MAX_PINGS_WITHOUT_DATA=0
export GRPC_HTTP2_MIN_RECV_PING_INTERVAL_WITHOUT_DATA_MS=300000  # 5 minutes

# Run with DirectRunner for local testing with multi-processing
python trips_to_staypoints/main.py \
    --input="$INPUT_FILE" \
    --output="$OUTPUT_PREFIX" \
    --output_format=hive \
    --runner=DirectRunner \
    --direct_num_workers=0 \
    --direct_running_mode=multi_processing \
    --direct_worker_memory_mb=512

echo "Local test completed!"
echo "Check output files in the output/ directory"
