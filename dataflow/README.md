# Trips to Staypoints Dataflow Job

This directory contains a Python Dataflow job that replicates the logic from `trips_to_staypoints.sql` using Apache Beam.

## Overview

The Dataflow job processes trip data and converts it to staypoints data by:
1. Reading trip data from Iceberg table in Parquet format
2. Grouping trips by user_id
3. Creating staypoints using window functions (LEAD)
4. Aggregating staypoints per user with partition keys
5. Outputting results in JSON, CSV, or Hive-partitioned Parquet format

## Files

- `trips_to_staypoints/main.py` - Main Dataflow pipeline
- `requirements_dataflow.txt` - Python dependencies
- `run_dataflow_job.sh` - Script to run on Google Cloud Dataflow
- `test_dataflow_local.sh` - Script to test locally
- `README.md` - This file

## Setup

### 1. Install Dependencies

```bash
pip install -r requirements_dataflow.txt
```

### 2. Local Testing

```bash
# Make sure you have a trips.parquet file in the current directory
./test_dataflow_local.sh
```

### 3. Google Cloud Dataflow Deployment

1. Set up your GCP project and enable Dataflow API
2. Update the configuration in `run_dataflow_job.sh`:
   - Set your `PROJECT_ID`
   - Update bucket paths for input/output
   - Adjust other parameters as needed

3. Run the job:
```bash
./run_dataflow_job.sh
```

## Input Data Format

The job reads from an Iceberg table in Parquet format with the following schema:
```
user_id: VARCHAR
trip_start_time: TIMESTAMP
trip_end_time: TIMESTAMP
start_lat: DOUBLE
start_lng: DOUBLE
end_lat: DOUBLE
end_lng: DOUBLE
```

The input corresponds to the `trips_data.trips` table created in `starburst_import.sql` (line 52), which is an Iceberg table with Parquet format partitioned by hour(trip_start_time).

## Output Format

The job supports three output formats:

### JSON Output
```json
{
  "user_id": "user123",
  "staypoints": [
    {
      "enter_time": "2025-01-01 10:30:00.000",
      "exit_time": "2025-01-01 11:00:00.000",
      "lat": 40.7589,
      "lng": -73.9851
    }
  ],
  "p1": "us",
  "p2": "er"
}
```

### CSV Output
```
user_id,p1,p2,staypoints_json
user123,us,er,"[{\"enter_time\":\"2025-01-01 10:30:00.000\",\"exit_time\":\"2025-01-01 11:00:00.000\",\"lat\":40.7589,\"lng\":-73.9851}]"
```

### Hive Partitioned Parquet Output
Creates a Hive-style partitioned directory structure:
```
output/
├── p1=us/p2=er/
│   └── data.parquet
├── p1=ab/p2=cd/
│   └── data.parquet
└── ...
```

Each Parquet file contains:
- `user_id`: User identifier
- `staypoints`: Array of staypoint records
- `p1`, `p2`: Partition keys (also stored in data)

This format is compatible with Hive/Spark queries and provides efficient partitioning for analytics.

## Key Features

- **Scalable**: Uses Apache Beam for distributed processing
- **Fault-tolerant**: Built-in retry and error handling
- **Flexible**: Supports both local testing and cloud deployment
- **Partitioned**: Creates partition keys (p1, p2) from user_id
- **Window Functions**: Implements LEAD window function logic
- **Data Validation**: Handles malformed data gracefully
- **Multiple Output Formats**: JSON, CSV, and Hive-partitioned Parquet

## SQL to Dataflow Mapping

| SQL Concept | Dataflow Implementation |
|-------------|------------------------|
| `PARTITION BY user_id ORDER BY trip_start_time` | Group by user_id, sort trips by start time |
| `LEAD(trip_start_time) OVER user_trips` | Manual iteration with next trip's start time |
| `ARRAY_AGG(staypoint)` | Collect staypoints into list |
| `substr(user_id, 1, 2) AS p1` | String slicing for partition keys |
| `WHERE staypoint.exit_time IS NOT NULL` | Filter out null exit times |

## Monitoring

- **Local**: Check console output and output files
- **Cloud**: Monitor via Google Cloud Console Dataflow section
- **Logs**: Available in Cloud Logging for cloud runs

## Troubleshooting

1. **Memory issues**: Increase `disk_size_gb` or `machine_type`
2. **Timeout**: Increase `max_num_workers` or adjust batch size
3. **Data format errors**: Check input Parquet schema matches expected format
4. **Permission errors**: Ensure service account has necessary GCS/BigQuery permissions
