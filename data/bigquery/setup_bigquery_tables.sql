-- SQL script to set up BigQuery tables for the Dataflow job
-- Run this in BigQuery console or using bq command line tool

-- 1. Create the trips table (if it doesn't exist)
CREATE TABLE IF NOT EXISTS `your-project.trips_data.trips` (
  user_id STRING NOT NULL,
  trip_start_time TIMESTAMP NOT NULL,
  trip_end_time TIMESTAMP NOT NULL,
  start_lat FLOAT64 NOT NULL,
  start_lng FLOAT64 NOT NULL,
  end_lat FLOAT64 NOT NULL,
  end_lng FLOAT64 NOT NULL
)
PARTITION BY DATE(trip_start_time)
CLUSTER BY user_id;

-- 2. Create the staypoints table (output table)
CREATE TABLE IF NOT EXISTS `your-project.trips_data.staypoints` (
  user_id STRING NOT NULL,
  staypoints ARRAY<STRUCT<
    enter_time TIMESTAMP,
    exit_time TIMESTAMP,
    lat FLOAT64,
    lng FLOAT64
  >> NOT NULL,
  p1 STRING NOT NULL,
  p2 STRING NOT NULL
)
PARTITION BY DATE(CURRENT_TIMESTAMP())
CLUSTER BY user_id, p1, p2;

-- 3. Insert sample data into trips table
INSERT INTO `your-project.trips_data.trips`
(user_id, trip_start_time, trip_end_time, start_lat, start_lng, end_lat, end_lng)
VALUES
('user-001', '2025-01-01 08:00:00', '2025-01-01 08:30:00', 40.7589, -73.9851, 40.7614, -73.9776),
('user-001', '2025-01-01 09:00:00', '2025-01-01 09:45:00', 40.7614, -73.9776, 40.7505, -73.9934),
('user-001', '2025-01-01 10:30:00', '2025-01-01 11:15:00', 40.7505, -73.9934, 40.7589, -73.9851),
('user-002', '2025-01-01 07:30:00', '2025-01-01 08:00:00', 37.7749, -122.4194, 37.7849, -122.4094),
('user-002', '2025-01-01 08:30:00', '2025-01-01 09:00:00', 37.7849, -122.4094, 37.7949, -122.3994);

-- 4. Query to verify the data
SELECT
  user_id,
  COUNT(*) as trip_count,
  MIN(trip_start_time) as first_trip,
  MAX(trip_end_time) as last_trip
FROM `your-project.trips_data.trips`
GROUP BY user_id
ORDER BY user_id;
