#!/usr/bin/env python3
"""
Dataflow job to convert trips data to staypoints data using BigQuery as source.
This shows how to integrate BigQuery with Apache Beam Dataflow.
"""

import logging
from datetime import datetime
from typing import Dict, Tuple, Any, Iterator, Iterable
import json

import apache_beam as beam
from apache_beam.options.pipeline_options import PipelineOptions
from apache_beam.io import WriteToText
from apache_beam.io.gcp.bigquery import ReadFromBigQuery, WriteToBigQuery
from apache_beam.io.gcp.internal.clients import bigquery

from models import TripData, StaypointData, UserStaypoints


class CustomPipelineOptions(PipelineOptions):
    """Custom pipeline options to include our custom arguments."""

    @classmethod
    def _add_argparse_args(cls, parser):
        parser.add_argument('--input_table', required=True,
                          help='BigQuery input table in format project.dataset.table')
        parser.add_argument('--output_table', required=True,
                          help='BigQuery output table in format project.dataset.table')
        parser.add_argument('--output_format', default='bigquery',
                          choices=['bigquery', 'json', 'csv', 'hive'],
                          help='Output format (bigquery, json, csv, or hive)')


class ParseTripDataFromBigQuery(beam.DoFn):
    """Parse BigQuery row into TripData object."""

    def process(self, element: Dict[str, Any]) -> Iterator[TripData]:
        try:
            # Extract data from BigQuery row dictionary
            user_id = str(element['user_id'])
            trip_start_time = element['trip_start_time']
            trip_end_time = element['trip_end_time']
            start_lat = float(element['start_lat'])
            start_lng = float(element['start_lng'])
            end_lat = float(element['end_lat'])
            end_lng = float(element['end_lng'])

            # Parse timestamps (BigQuery returns datetime objects)
            if isinstance(trip_start_time, str):
                trip_start_time = datetime.fromisoformat(trip_start_time.replace('Z', '+00:00'))
            if isinstance(trip_end_time, str):
                trip_end_time = datetime.fromisoformat(trip_end_time.replace('Z', '+00:00'))

            trip = TripData(user_id, trip_start_time, trip_end_time,
                          start_lat, start_lng, end_lat, end_lng)

            yield trip

        except Exception as e:
            logging.error(f"Error parsing trip data: {e}, row: {element}")


class CreateStaypoints(beam.DoFn):
    """Create staypoints from trips data for each user."""

    def process(self, element: Tuple[Any, Iterable[TripData]]) -> Iterator[UserStaypoints]:
        user_id, trips_iterable = element

        # Convert iterable to list and sort trips by start time
        trips = list(trips_iterable)
        trips.sort(key=lambda t: t.trip_start_time)

        staypoints = []

        # Create staypoints using LEAD window function logic
        for i, trip in enumerate(trips):
            # Skip the last trip
            if i + 1 >= len(trips):
                continue

            # Get the next trip's start time (equivalent to lead(trip_start_time) OVER user_trips)
            next_trip_start = trips[i + 1].trip_start_time

            # Create staypoint: (trip_end_time, next_trip_start_time, end_lat, end_lng)
            staypoint = StaypointData(
                enter_time=trip.trip_end_time,
                exit_time=next_trip_start,
                lat=trip.end_lat,
                lng=trip.end_lng
            )

            # Add staypoint to list
            staypoints.append(staypoint)

        # Create partition keys (equivalent to substr(user_id, 1, 2) AS p1, substr(user_id, 3, 2) AS p2)
        p1 = user_id[:2] if len(user_id) >= 2 else user_id
        p2 = user_id[2:4] if len(user_id) >= 4 else ""

        # Yield user staypoints
        if len(staypoints) > 0:
            user_staypoints = UserStaypoints(user_id, staypoints, p1, p2)
            yield user_staypoints


class FormatForBigQuery(beam.DoFn):
    """Format output for BigQuery writing."""

    def process(self, element: UserStaypoints) -> Iterator[Dict[str, Any]]:
        # Convert to BigQuery-compatible format
        staypoints_list = []
        for sp in element.staypoints:
            staypoints_list.append({
                'enter_time': sp.enter_time.isoformat(),
                'exit_time': sp.exit_time.isoformat(),
                'lat': sp.lat,
                'lng': sp.lng
            })

        yield {
            'user_id': element.user_id,
            'staypoints': staypoints_list,
            'p1': element.p1,
            'p2': element.p2
        }


def run_pipeline(argv=None):
    """Main pipeline function with BigQuery integration."""

    # Set up pipeline options with custom arguments
    opts = CustomPipelineOptions(argv)

    with beam.Pipeline(options=opts) as pipeline:
        # Read input data from BigQuery
        trips = (
            pipeline
            | 'ReadFromBigQuery' >> ReadFromBigQuery(
                query=f"""
                SELECT
                    user_id,
                    trip_start_time,
                    trip_end_time,
                    start_lat,
                    start_lng,
                    end_lat,
                    end_lng
                FROM `{opts.input_table}`
                WHERE trip_start_time >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY)
                ORDER BY user_id, trip_start_time
                """,
                use_standard_sql=True,
                # Alternative: Read entire table without query
                # table=f"{opts.input_table}",
            )
            | 'ParseTripData' >> beam.ParDo(ParseTripDataFromBigQuery())
        )

        # Group by user_id (equivalent to PARTITION BY user_id)
        user_trips = (
            trips
            | 'KeyByUser' >> beam.Map(lambda trip: (trip.user_id, trip))
            | 'GroupByUser' >> beam.GroupByKey()
        )

        # Create staypoints for each user
        staypoints = (
            user_trips
            | 'CreateStaypoints' >> beam.ParDo(CreateStaypoints())
        )

        # Format and write output
        if opts.output_format == 'bigquery':
            # Write to BigQuery
            output = (
                staypoints
                | 'FormatForBigQuery' >> beam.ParDo(FormatForBigQuery())
                | 'WriteToBigQuery' >> WriteToBigQuery(
                    table=f"{opts.output_table}",
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
                            bigquery.TableFieldSchema(name='p1', type='STRING', mode='REQUIRED'),
                            bigquery.TableFieldSchema(name='p2', type='STRING', mode='REQUIRED'),
                        ]
                    ),
                    write_disposition=WriteToBigQuery.WriteDisposition.WRITE_TRUNCATE,
                    create_disposition=WriteToBigQuery.CreateDisposition.CREATE_IF_NEEDED,
                )
            )
        elif opts.output_format == 'json':
            output = (
                staypoints
                | 'FormatJSON' >> beam.Map(lambda x: json.dumps(x.to_dict()))
                | 'WriteOutput' >> WriteToText(f"{opts.output_table}_json", file_name_suffix='.json')
            )
        elif opts.output_format == 'csv':
            output = (
                staypoints
                | 'FormatCSV' >> beam.Map(lambda x: f"{x.user_id},{x.p1},{x.p2},{json.dumps([sp.to_dict() for sp in x.staypoints])}")
                | 'WriteOutput' >> WriteToText(f"{opts.output_table}_csv", file_name_suffix='.csv')
            )
        else:  # hive format - would need additional implementation
            logging.warning("Hive format not implemented for BigQuery source")


if __name__ == '__main__':
    logging.getLogger().setLevel(logging.INFO)
    run_pipeline()
