#!/bin/bash

# Check if trips argument is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <total_trips_across_all_files>"
    echo "Example: $0 3000000000"
    echo "This will generate 10 files with 300,000,000 trips each (total: 3 billion trips)"
    exit 1
fi

TOTAL_TRIPS_ALL_FILES=$1
TRIPS_PER_FILE=$((TOTAL_TRIPS_ALL_FILES / 10))

# Generate 10 sets of trips, each running in the background
echo "Starting generation of $TOTAL_TRIPS_ALL_FILES total trips across 10 files..."
echo "Each file will contain $TRIPS_PER_FILE trips"

for i in {1..10}; do
    echo "Starting background job $i: generating $TRIPS_PER_FILE trips to trips${i}.csv"
    python3 generate_trips.py --trips $TRIPS_PER_FILE --output "trips${i}.csv" &
done

echo "All 10 background jobs started!"
echo "Use 'jobs' to see running jobs"
echo "Use 'wait' to wait for all jobs to complete"
echo "Use 'ps aux | grep generate_trips' to see running processes"
