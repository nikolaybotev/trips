CREATE TABLE staypoints2
WITH (
    type = 'HIVE',
    format = 'PARQUET',
    partitioned_by = ARRAY['p1', 'p2']
)
AS (
    SELECT
        user_id,
        ARRAY_AGG(staypoint) AS staypoints,
        substr(user_id, 1, 2) AS p1,
        substr(user_id, 3, 2) AS p2
    FROM (
        SELECT
            user_id,
            CAST(ROW(
                trip_end_time,
                lead(trip_start_time) OVER user_trips,
                end_lat,
                end_lng
            ) AS ROW(
                enter_time TIMESTAMP(3),
                exit_time TIMESTAMP(3),
                lat DOUBLE,
                lng DOUBLE
            )) as staypoint
        FROM trips
        WINDOW user_trips AS (PARTITION BY user_id ORDER BY trip_start_time ASC)
    )
    WHERE staypoint.exit_time IS NOT NULL
    GROUP BY 1, 3, 4
)
