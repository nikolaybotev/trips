-- Starburst SQL Script to Import Trip CSV Files
-- This script implements Method 1: Using Hive Connector with External Location

-- Step 1: Create schema (if it doesn't exist)
CREATE SCHEMA IF NOT EXISTS trips_data;

-- Step 2: Create table for trip data
-- Note: All columns are VARCHAR as required by CSV format in Starburst
CREATE TABLE trips_data.trips_raw (
    user_id VARCHAR,
    trip_start_time VARCHAR,
    trip_end_time VARCHAR,
    start_lat VARCHAR,
    start_lng VARCHAR,
    end_lat VARCHAR,
    end_lng VARCHAR
)
WITH (
    format = 'CSV',
    external_location = 's3://feelinsosweet-starburst/trips-data/',
    skip_header_line_count = 1
);

-- Step 2b: Create a view with proper data types
-- This view casts VARCHAR columns to appropriate types including DOUBLE for coordinates
-- Using REPLACE to convert ISO format to Starburst-compatible timestamp format
CREATE OR REPLACE VIEW trips_data.trips_view AS
SELECT
    user_id,
    CAST(REPLACE(REPLACE(trip_start_time, 'T', ' '), 'Z', '') AS TIMESTAMP) AS trip_start_time,
    CAST(REPLACE(REPLACE(trip_end_time, 'T', ' '), 'Z', '') AS TIMESTAMP) AS trip_end_time,
    CAST(start_lat AS DOUBLE) AS start_lat,
    CAST(start_lng AS DOUBLE) AS start_lng,
    CAST(end_lat AS DOUBLE) AS end_lat,
    CAST(end_lng AS DOUBLE) AS end_lng
FROM trips_data.trips_raw;

-- Alternative approach using date_parse (uncomment if REPLACE approach doesn't work)
-- CREATE VIEW trips_data.trips AS
-- SELECT
--     user_id,
--     date_parse(trip_start_time, '%Y-%m-%dT%H:%i:%s.%fZ') AS trip_start_time,
--     date_parse(trip_end_time, '%Y-%m-%dT%H:%i:%s.%fZ') AS trip_end_time,
--     CAST(start_lat AS DOUBLE) AS start_lat,
--     CAST(start_lng AS DOUBLE) AS start_lng,
--     CAST(end_lat AS DOUBLE) AS end_lat,
--     CAST(end_lng AS DOUBLE) AS end_lng
-- FROM trips_data.trips_raw;


-- Step 2c: Create a table from the view in iceberg format
CREATE TABLE trips_data.trips
WITH (
    type = 'iceberg',
    format = 'parquet',
    location = 's3://feelinsosweet-starburst/trips-iceberg/',
    partitioning = ARRAY['hour(trip_start_time)']
)
AS (
    SELECT * FROM trips_data.trips_view
);


-- Step 3: Query examples
-- Basic query (lat/lng are now DOUBLE type in the view)
SELECT * FROM trips_data.trips LIMIT 10;

-- Query with proper data types (no casting needed for lat/lng)
SELECT
    user_id,
    trip_start_time,
    trip_end_time,
    start_lat,
    start_lng,
    end_lat,
    end_lng
FROM trips_data.trips
LIMIT 10;

-- Example analytical queries
-- Count trips per user
SELECT
    user_id,
    COUNT(*) as trip_count
FROM trips_data.trips
GROUP BY user_id
ORDER BY trip_count DESC
LIMIT 10;

-- Calculate trip duration
SELECT
    user_id,
    trip_start_time,
    trip_end_time,
    trip_end_time - trip_start_time AS trip_duration
FROM trips_data.trips
LIMIT 10;

-- Find trips within a specific time range
SELECT *
FROM trips_data.trips
WHERE trip_start_time >= TIMESTAMP '2025-08-01 00:00:00'
  AND trip_start_time < TIMESTAMP '2025-08-02 00:00:00'
LIMIT 10;

-- Geographic analysis - trips starting in specific region
SELECT *
FROM trips_data.trips
WHERE start_lat BETWEEN 40.0 AND 50.0
  AND start_lng BETWEEN -80.0 AND -70.0
LIMIT 10;
