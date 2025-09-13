#!/bin/bash

# Check if trips argument is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <total_trips_across_all_files>"
    echo "Example: $0 3000000000"
    echo "This will generate files with trips distributed across all CPU cores"
    exit 1
fi

# Get number of CPU cores (cross-platform)
if command -v nproc >/dev/null 2>&1; then
    # Linux
    NUM_CORES=$(nproc)
elif command -v sysctl >/dev/null 2>&1; then
    # macOS
    NUM_CORES=$(sysctl -n hw.ncpu)
else
    # Fallback for other Unix-like systems
    NUM_CORES=$(grep -c ^processor /proc/cpuinfo 2>/dev/null || echo 1)
fi
TOTAL_TRIPS_ALL_FILES=$1
TRIPS_PER_FILE=$((TOTAL_TRIPS_ALL_FILES / NUM_CORES))

# Generate trips files, one per CPU core, each running in the background
echo "Detected $NUM_CORES CPU cores"
echo "Starting generation of $TOTAL_TRIPS_ALL_FILES total trips across $NUM_CORES files..."
echo "Each file will contain $TRIPS_PER_FILE trips"

for i in $(seq 1 $NUM_CORES); do
    echo "Starting background job $i: generating $TRIPS_PER_FILE trips to trips${i}.csv"
    python3 generate_trips.py --trips $TRIPS_PER_FILE --output "trips${i}.csv" &
done

echo "All $NUM_CORES background jobs started!"
echo "Use 'jobs' to see running jobs"
echo "Use 'wait' to wait for all jobs to complete"
echo "Use 'ps aux | grep generate_trips' to see running processes"
