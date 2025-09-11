#!/bin/bash

# Generate 10 sets of 300 million trips, each running in the background
echo "Starting generation of 10 sets of 300 million trips..."

for i in {1..10}; do
    echo "Starting background job $i: generating 300,000,000 trips to trips${i}.csv"
    python3 generate_trips.py --trips 300000000 --output "trips${i}.csv" &
done

echo "All 10 background jobs started!"
echo "Use 'jobs' to see running jobs"
echo "Use 'wait' to wait for all jobs to complete"
echo "Use 'ps aux | grep generate_trips' to see running processes"
