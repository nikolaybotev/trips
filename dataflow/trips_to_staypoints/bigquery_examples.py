#!/usr/bin/env python3
"""
Comprehensive examples of BigQuery integration with Apache Beam Dataflow.
This file demonstrates various patterns for reading from and writing to BigQuery.
"""

import apache_beam as beam
from apache_beam.options.pipeline_options import PipelineOptions
from apache_beam.io.gcp.bigquery import ReadFromBigQuery, WriteToBigQuery
from apache_beam.io.gcp.internal.clients import bigquery


def example_1_read_entire_table():
    """
    Example 1: Read entire BigQuery table
    """
    with beam.Pipeline() as pipeline:
        # Read entire table
        data = (
            pipeline
            | 'ReadTable' >> ReadFromBigQuery(
                table='project.dataset.table_name',
                use_standard_sql=False
            )
        )
        # Process data...
        data | beam.Map(print)


def example_2_read_with_sql_query():
    """
    Example 2: Read with SQL query
    """
    with beam.Pipeline() as pipeline:
        # Read with custom SQL query
        data = (
            pipeline
            | 'ReadWithQuery' >> ReadFromBigQuery(
                query="""
                SELECT
                    user_id,
                    trip_start_time,
                    trip_end_time,
                    start_lat,
                    start_lng,
                    end_lat,
                    end_lng
                FROM `project.dataset.trips`
                WHERE trip_start_time >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)
                AND user_id IN ('user1', 'user2', 'user3')
                ORDER BY user_id, trip_start_time
                """,
                use_standard_sql=True
            )
        )
        # Process data...
        data | beam.Map(print)


def example_3_read_with_parameters():
    """
    Example 3: Read with parameterized query
    """
    with beam.Pipeline() as pipeline:
        # Read with parameterized query
        data = (
            pipeline
            | 'ReadWithParams' >> ReadFromBigQuery(
                query="""
                SELECT
                    user_id,
                    trip_start_time,
                    trip_end_time,
                    start_lat,
                    start_lng,
                    end_lat,
                    end_lng
                FROM `project.dataset.trips`
                WHERE trip_start_time >= @start_date
                AND trip_start_time <= @end_date
                AND region = @region_name
                """,
                use_standard_sql=True,
                query_parameters=[
                    bigquery.ScalarQueryParameter('start_date', 'TIMESTAMP', '2025-01-01 00:00:00'),
                    bigquery.ScalarQueryParameter('end_date', 'TIMESTAMP', '2025-01-31 23:59:59'),
                    bigquery.ScalarQueryParameter('region_name', 'STRING', 'US')
                ]
            )
        )
        # Process data...
        data | beam.Map(print)


def example_4_write_to_bigquery():
    """
    Example 4: Write to BigQuery table
    """
    with beam.Pipeline() as pipeline:
        # Create sample data
        data = (
            pipeline
            | 'CreateData' >> beam.Create([
                {'user_id': 'user1', 'staypoints': [{'lat': 40.7589, 'lng': -73.9851}]},
                {'user_id': 'user2', 'staypoints': [{'lat': 37.7749, 'lng': -122.4194}]},
            ])
        )

        # Write to BigQuery
        data | 'WriteToBigQuery' >> WriteToBigQuery(
            table='project.dataset.staypoints',
            schema=bigquery.TableSchema(
                fields=[
                    bigquery.TableFieldSchema(name='user_id', type='STRING', mode='REQUIRED'),
                    bigquery.TableFieldSchema(name='staypoints', type='RECORD', mode='REPEATED',
                        fields=[
                            bigquery.TableFieldSchema(name='lat', type='FLOAT', mode='REQUIRED'),
                            bigquery.TableFieldSchema(name='lng', type='FLOAT', mode='REQUIRED'),
                        ]
                    ),
                ]
            ),
            write_disposition=WriteToBigQuery.WriteDisposition.WRITE_TRUNCATE,
            create_disposition=WriteToBigQuery.CreateDisposition.CREATE_IF_NEEDED,
        )


def example_5_write_with_dynamic_destination():
    """
    Example 5: Write to different tables based on data
    """
    with beam.Pipeline() as pipeline:
        # Create sample data with different regions
        data = (
            pipeline
            | 'CreateData' >> beam.Create([
                {'user_id': 'user1', 'region': 'US', 'staypoints': [{'lat': 40.7589, 'lng': -73.9851}]},
                {'user_id': 'user2', 'region': 'EU', 'staypoints': [{'lat': 51.5074, 'lng': -0.1278}]},
                {'user_id': 'user3', 'region': 'US', 'staypoints': [{'lat': 37.7749, 'lng': -122.4194}]},
            ])
        )

        # Write to different tables based on region
        data | 'WriteToBigQuery' >> WriteToBigQuery(
            table=lambda row: f'project.dataset.staypoints_{row["region"].lower()}',
            schema=bigquery.TableSchema(
                fields=[
                    bigquery.TableFieldSchema(name='user_id', type='STRING', mode='REQUIRED'),
                    bigquery.TableFieldSchema(name='region', type='STRING', mode='REQUIRED'),
                    bigquery.TableFieldSchema(name='staypoints', type='RECORD', mode='REPEATED',
                        fields=[
                            bigquery.TableFieldSchema(name='lat', type='FLOAT', mode='REQUIRED'),
                            bigquery.TableFieldSchema(name='lng', type='FLOAT', mode='REQUIRED'),
                        ]
                    ),
                ]
            ),
            write_disposition=WriteToBigQuery.WriteDisposition.WRITE_TRUNCATE,
            create_disposition=WriteToBigQuery.CreateDisposition.CREATE_IF_NEEDED,
        )


def example_6_read_write_pipeline():
    """
    Example 6: Complete read-process-write pipeline
    """
    with beam.Pipeline() as pipeline:
        # Read from BigQuery
        trips = (
            pipeline
            | 'ReadTrips' >> ReadFromBigQuery(
                query="""
                SELECT
                    user_id,
                    trip_start_time,
                    trip_end_time,
                    start_lat,
                    start_lng,
                    end_lat,
                    end_lng
                FROM `project.dataset.trips`
                WHERE trip_start_time >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY)
                """,
                use_standard_sql=True
            )
        )

        # Process data (group by user, create staypoints)
        staypoints = (
            trips
            | 'KeyByUser' >> beam.Map(lambda row: (row['user_id'], row))
            | 'GroupByUser' >> beam.GroupByKey()
            | 'CreateStaypoints' >> beam.Map(create_staypoints_for_user)
        )

        # Write back to BigQuery
        staypoints | 'WriteStaypoints' >> WriteToBigQuery(
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


def create_staypoints_for_user(user_trips):
    """Helper function to create staypoints for a user."""
    user_id, trips = user_trips
    trips_list = list(trips)
    trips_list.sort(key=lambda t: t['trip_start_time'])

    staypoints = []
    for i, trip in enumerate(trips_list):
        if i + 1 < len(trips_list):
            next_trip = trips_list[i + 1]
            staypoint = {
                'enter_time': trip['trip_end_time'],
                'exit_time': next_trip['trip_start_time'],
                'lat': trip['end_lat'],
                'lng': trip['end_lng']
            }
            staypoints.append(staypoint)

    return {
        'user_id': user_id,
        'staypoints': staypoints
    }


def example_7_bigquery_with_side_inputs():
    """
    Example 7: Using BigQuery with side inputs for lookups
    """
    with beam.Pipeline() as pipeline:
        # Read main data
        trips = (
            pipeline
            | 'ReadTrips' >> ReadFromBigQuery(
                table='project.dataset.trips',
                use_standard_sql=False
            )
        )

        # Read lookup data as side input
        user_profiles = (
            pipeline
            | 'ReadUserProfiles' >> ReadFromBigQuery(
                query="SELECT user_id, region, user_type FROM `project.dataset.user_profiles`",
                use_standard_sql=True
            )
        )

        # Create side input dictionary
        user_profiles_dict = beam.pvalue.AsDict(
            user_profiles | beam.Map(lambda row: (row['user_id'], row))
        )

        # Enrich trips with user profile data
        enriched_trips = (
            trips
            | 'EnrichWithProfile' >> beam.Map(
                lambda trip, profiles: enrich_trip_with_profile(trip, profiles),
                profiles=user_profiles_dict
            )
        )

        # Write enriched data
        enriched_trips | 'WriteEnriched' >> WriteToBigQuery(
            table='project.dataset.enriched_trips',
            write_disposition=WriteToBigQuery.WriteDisposition.WRITE_TRUNCATE,
        )


def enrich_trip_with_profile(trip, profiles):
    """Helper function to enrich trip with profile data."""
    user_id = trip['user_id']
    profile = profiles.get(user_id, {})

    return {
        **trip,
        'region': profile.get('region', 'Unknown'),
        'user_type': profile.get('user_type', 'Standard')
    }


if __name__ == '__main__':
    # Run a specific example
    example_6_read_write_pipeline()
