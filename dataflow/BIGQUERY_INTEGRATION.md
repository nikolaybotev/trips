# BigQuery Integration with Apache Beam Dataflow

This guide shows how to integrate BigQuery as a data source and destination in your Apache Beam Dataflow jobs.

## Overview

BigQuery integration in Apache Beam allows you to:
- **Read data** from BigQuery tables using SQL queries or full table scans
- **Write data** to BigQuery tables with automatic schema handling
- **Process large datasets** efficiently with BigQuery's distributed processing
- **Use parameterized queries** for dynamic data filtering
- **Handle complex data types** including nested records and arrays

## Key Components

### 1. Reading from BigQuery

```python
from apache_beam.io.gcp.bigquery import ReadFromBigQuery

# Read entire table
data = (
    pipeline
    | 'ReadTable' >> ReadFromBigQuery(
        table='project.dataset.table_name',
        use_standard_sql=False
    )
)

# Read with SQL query
data = (
    pipeline
    | 'ReadWithQuery' >> ReadFromBigQuery(
        query="""
        SELECT user_id, trip_start_time, trip_end_time
        FROM `project.dataset.trips`
        WHERE trip_start_time >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)
        """,
        use_standard_sql=True
    )
)
```

### 2. Writing to BigQuery

```python
from apache_beam.io.gcp.bigquery import WriteToBigQuery
from apache_beam.io.gcp.internal.clients import bigquery

# Write with schema definition
data | 'WriteToBigQuery' >> WriteToBigQuery(
    table='project.dataset.staypoints',
    schema=bigquery.TableSchema(
        fields=[
            bigquery.TableFieldSchema(name='user_id', type='STRING', mode='REQUIRED'),
            bigquery.TableFieldSchema(name='staypoints', type='RECORD', mode='REPEATED',
                fields=[
                    bigquery.TableFieldSchema(name='enter_time', type='TIMESTAMP', mode='REQUIRED'),
                    bigquery.TableFieldSchema(name='exit_time', type='TIMESTAMP', mode='REQUIRED'),
                    bigquery.TableFieldSchema(name='lat', type='FLOAT', mode='REQUIRED'),
                    bigquery.TableFieldSchema(name='lng', type='FLOAT', mode='REQUIRED'),
                ]
            ),
        ]
    ),
    write_disposition=WriteToBigQuery.WriteDisposition.WRITE_TRUNCATE,
    create_disposition=WriteToBigQuery.CreateDisposition.CREATE_IF_NEEDED,
)
```

## Files Created

1. **`main_bigquery.py`** - Complete Dataflow job using BigQuery as source
2. **`bigquery_examples.py`** - Comprehensive examples of BigQuery integration patterns
3. **`run_bigquery_dataflow_job.sh`** - Deployment script for BigQuery-based job
4. **`setup_bigquery_tables.sql`** - SQL script to create required BigQuery tables

## Setup Instructions

### 1. Create BigQuery Tables

Run the SQL script to create the required tables:

```bash
# Using bq command line tool
bq query --use_legacy_sql=false < setup_bigquery_tables.sql

# Or run in BigQuery console
```

### 2. Update Configuration

Edit `run_bigquery_dataflow_job.sh` to set your project details:

```bash
INPUT_TABLE="${PROJECT_ID}.trips_data.trips"
OUTPUT_TABLE="${PROJECT_ID}.trips_data.staypoints"
```

### 3. Deploy the Job

```bash
# Make sure you're authenticated with Google Cloud
gcloud auth application-default login

# Run the BigQuery Dataflow job
./run_bigquery_dataflow_job.sh
```

## BigQuery Integration Patterns

### Pattern 1: Simple Table Read
```python
ReadFromBigQuery(table='project.dataset.table_name')
```

### Pattern 2: SQL Query with Filtering
```python
ReadFromBigQuery(
    query="SELECT * FROM `project.dataset.trips` WHERE date >= '2025-01-01'",
    use_standard_sql=True
)
```

### Pattern 3: Parameterized Query
```python
ReadFromBigQuery(
    query="SELECT * FROM `project.dataset.trips` WHERE date >= @start_date",
    use_standard_sql=True,
    query_parameters=[
        bigquery.ScalarQueryParameter('start_date', 'DATE', '2025-01-01')
    ]
)
```

### Pattern 4: Dynamic Table Writing
```python
WriteToBigQuery(
    table=lambda row: f'project.dataset.staypoints_{row["region"]}',
    schema=schema
)
```

### Pattern 5: Side Inputs for Lookups
```python
# Read lookup data
user_profiles = pipeline | 'ReadProfiles' >> ReadFromBigQuery(...)

# Create side input
profiles_dict = beam.pvalue.AsDict(
    user_profiles | beam.Map(lambda row: (row['user_id'], row))
)

# Use in main pipeline
enriched_data = (
    main_data
    | 'Enrich' >> beam.Map(
        lambda row, profiles: enrich_with_profile(row, profiles),
        profiles=profiles_dict
    )
)
```

## Data Types and Schema

### BigQuery Data Types
- **STRING** - Text data
- **INTEGER/INT64** - Integer numbers
- **FLOAT/FLOAT64** - Floating point numbers
- **BOOLEAN** - True/false values
- **TIMESTAMP** - Date and time
- **DATE** - Date only
- **TIME** - Time only
- **RECORD** - Nested objects
- **ARRAY** - Arrays of values

### Schema Modes
- **REQUIRED** - Field must have a value
- **NULLABLE** - Field can be null
- **REPEATED** - Field can have multiple values (array)

### Example Complex Schema
```python
schema = bigquery.TableSchema(
    fields=[
        bigquery.TableFieldSchema(name='user_id', type='STRING', mode='REQUIRED'),
        bigquery.TableFieldSchema(name='staypoints', type='RECORD', mode='REPEATED',
            fields=[
                bigquery.TableFieldSchema(name='enter_time', type='TIMESTAMP', mode='REQUIRED'),
                bigquery.TableFieldSchema(name='exit_time', type='TIMESTAMP', mode='REQUIRED'),
                bigquery.TableFieldSchema(name='location', type='RECORD', mode='REQUIRED',
                    fields=[
                        bigquery.TableFieldSchema(name='lat', type='FLOAT', mode='REQUIRED'),
                        bigquery.TableFieldSchema(name='lng', type='FLOAT', mode='REQUIRED'),
                    ]
                ),
            ]
        ),
    ]
)
```

## Performance Considerations

### 1. Partitioning
- Use `PARTITION BY` for large tables
- Query only relevant partitions when possible
- Consider clustering for better performance

### 2. Query Optimization
- Use `LIMIT` for testing
- Filter early in the query
- Use appropriate data types

### 3. Write Optimization
- Use `WRITE_TRUNCATE` for full table replacement
- Use `WRITE_APPEND` for incremental updates
- Consider batch size for large writes

### 4. Cost Optimization
- Use `use_standard_sql=True` for better performance
- Avoid `SELECT *` when possible
- Use appropriate machine types for Dataflow workers

## Error Handling

### Common Issues and Solutions

1. **Schema Mismatch**
   ```python
   # Ensure your data matches the expected schema
   # Use explicit type conversion if needed
   ```

2. **Permission Errors**
   ```bash
   # Ensure service account has BigQuery permissions
   gcloud projects add-iam-policy-binding PROJECT_ID \
     --member="serviceAccount:SERVICE_ACCOUNT@PROJECT_ID.iam.gserviceaccount.com" \
     --role="roles/bigquery.dataEditor"
   ```

3. **Query Timeout**
   ```python
   # Use smaller date ranges or add LIMIT clause
   query = """
   SELECT * FROM `project.dataset.trips`
   WHERE trip_start_time >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 1 DAY)
   LIMIT 1000000
   """
   ```

## Monitoring and Debugging

### 1. BigQuery Console
- Monitor query performance
- Check data quality
- View table schemas

### 2. Dataflow Console
- Monitor job progress
- Check worker logs
- View metrics and errors

### 3. Cloud Logging
- Search for specific errors
- Monitor data processing
- Track performance metrics

## Best Practices

1. **Use Standard SQL** - Better performance and features
2. **Partition Large Tables** - Improve query performance
3. **Cluster Related Data** - Optimize for common query patterns
4. **Handle Errors Gracefully** - Use try-catch blocks
5. **Monitor Costs** - BigQuery charges by data processed
6. **Test with Small Datasets** - Validate logic before scaling
7. **Use Appropriate Data Types** - Optimize storage and performance
8. **Implement Retry Logic** - Handle transient failures

## Example Usage

```bash
# 1. Set up BigQuery tables
bq query --use_legacy_sql=false < setup_bigquery_tables.sql

# 2. Update configuration in run_bigquery_dataflow_job.sh
# 3. Deploy the job
./run_bigquery_dataflow_job.sh

# 4. Monitor in BigQuery console
# 5. Check results
bq query --use_legacy_sql=false "SELECT COUNT(*) FROM \`project.dataset.staypoints\`"
```

This integration provides a powerful way to process large-scale data using BigQuery's distributed processing capabilities combined with Apache Beam's flexible data processing framework.
