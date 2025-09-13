#!/bin/bash
# Script to test the Dataflow job locally

# Configuration for local testing
INPUT_FILE="input/**"  # Local Parquet file
OUTPUT_PREFIX="output/"

echo "Testing Dataflow job locally..."
echo "Input: $INPUT_FILE"
echo "Output: $OUTPUT_PREFIX"

# Create output directory if it doesn't exist
mkdir -p output

# Run with DirectRunner for local testing with multi-processing
python trips_to_staypoints_dataflow.py \
    --input="$INPUT_FILE" \
    --output="$OUTPUT_PREFIX" \
    --output_format=hive \
    --runner=DirectRunner \
    --direct_num_workers=0 \
    --direct_running_mode=multi_processing

echo "Local test completed!"
echo "Check output files in the output/ directory"
