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
- `trips_to_staypoints/models.py` - Data models and classes
- `trips_to_staypoints/requirements.txt` - Python dependencies
- `Dockerfile` - Container image definition
- `config.sh` - Configuration loader from Terraform
- `run_dataflow_job.sh` - Script to run on Google Cloud Dataflow
- `test_dataflow_local.sh` - Script to test locally
- `cicd/terraform/` - Infrastructure as Code configuration
- `input/` - Sample input data (Parquet files)
- `output/` - Dataflow job outputs
- `README.md` - This file

## Setup

### 1. Install Dependencies

```bash
pip install -r trips_to_staypoints/requirements.txt
```

### 2. Local Testing

```bash
# Make sure you have a trips.parquet file in the current directory
./test_dataflow_local.sh
```

### 3. Infrastructure Setup (Terraform)

Before deploying to Google Cloud Dataflow, set up the infrastructure:

```bash
cd cicd/terraform
terraform init
terraform plan
terraform apply
```

This creates:
- Service accounts with appropriate permissions
- Artifact Registry for container images
- GCS buckets for data storage
- VPC subnet for secure execution

### 4. Container Build and Deployment

1. Build the Docker container:
```bash
# Build and push container image
docker build -t trips-to-staypoints .
docker tag trips-to-staypoints gcr.io/PROJECT_ID/trips-to-staypoints
docker push gcr.io/PROJECT_ID/trips-to-staypoints
```

2. Run the Dataflow job:
```bash
# Load configuration from Terraform
source ./config.sh

# Deploy to Google Cloud Dataflow
./run_dataflow_job.sh
```

The deployment script automatically:
- Uses the containerized image
- Configures secure networking (no public IPs)
- Sets up proper service account permissions
- Enables performance optimizations

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
- **Containerized**: Docker-based deployment for reproducibility
- **Infrastructure as Code**: Terraform-managed GCP resources
- **Partitioned**: Creates partition keys (p1, p2) from user_id
- **Window Functions**: Implements LEAD window function logic
- **Data Validation**: Handles malformed data gracefully
- **Multiple Output Formats**: JSON, CSV, and Hive-partitioned Parquet
- **Performance Optimized**: Uses latest Dataflow features and SSD storage

## Configuration

The Dataflow job uses a configuration system that integrates with Terraform:

### Configuration Loading
- `config.sh` automatically loads settings from `cicd/terraform/terraform.tfvars`
- No manual configuration needed - everything is managed through Terraform
- Supports different environments through Terraform workspaces

### Key Configuration Parameters
- **Project ID**: GCP project for deployment
- **Region**: GCP region for resources
- **Service Account**: Dataflow worker service account
- **Artifact Registry**: Container image repository
- **Data Bucket**: GCS bucket for input/output data
- **Subnet**: VPC subnet for secure execution

### Performance Tuning
The deployment script includes optimized settings:
- **Runner v2**: Latest Dataflow runner with improved performance
- **Prime**: Enhanced autoscaling and resource management
- **Dynamic Thread Scaling**: Automatic thread optimization
- **Image Streaming**: Faster container startup
- **SSD Storage**: High-performance disk for workers

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
5. **Container build failures**: Check Dockerfile and requirements.txt syntax
6. **Terraform errors**: Verify GCP authentication and project permissions
7. **Network issues**: Ensure subnet has Private Google Access enabled
8. **Artifact Registry access**: Verify service account has container read permissions
9. **Configuration loading**: Check terraform.tfvars file exists and has correct format
10. **Local testing**: Ensure input Parquet files are in correct directory structure
