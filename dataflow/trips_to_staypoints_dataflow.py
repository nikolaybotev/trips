#!/usr/bin/env python3
"""
Dataflow job to convert trips data to staypoints data.
This replicates the logic from trips_to_staypoints.sql using Apache Beam.
"""

import argparse
import logging
from datetime import datetime
from typing import Dict, List, Tuple, Any, Iterator, Iterable
import json

import apache_beam as beam
from apache_beam.options.pipeline_options import PipelineOptions
from apache_beam.io import WriteToText
from apache_beam.io.parquetio import ReadFromParquet, WriteToParquet
import pyarrow as pa

from models import TripData, StaypointData, UserStaypoints


class ParseTripData(beam.DoFn):
    """Parse Parquet row into TripData object."""

    def process(self, element: Dict[str, Any]) -> Iterator[TripData]:
        try:
            # Extract data from Parquet row dictionary
            user_id = str(element['user_id'])
            trip_start_time = str(element['trip_start_time'])
            trip_end_time = str(element['trip_end_time'])
            start_lat = float(element['start_lat'])
            start_lng = float(element['start_lng'])
            end_lat = float(element['end_lat'])
            end_lng = float(element['end_lng'])

            # Parse timestamps (handle both string and datetime objects)
            trip_start_time = self._parse_timestamp(trip_start_time)
            trip_end_time = self._parse_timestamp(trip_end_time)

            trip = TripData(user_id, trip_start_time, trip_end_time,
                          start_lat, start_lng, end_lat, end_lng)

            yield trip

        except Exception as e:
            logging.error(f"Error parsing trip data: {e}, row: {element}")

    def _parse_timestamp(self, timestamp_value) -> datetime:
        """Parse timestamp from various formats."""
        try:
            if isinstance(timestamp_value, str):
                # Handle ISO format like "2025-01-01T12:00:00.000Z"
                if 'T' in timestamp_value and 'Z' in timestamp_value:
                    return datetime.fromisoformat(timestamp_value.replace('Z', '+00:00'))
                else:
                    return datetime.fromisoformat(timestamp_value)
            elif hasattr(timestamp_value, 'to_pydatetime'):
                # Handle Arrow timestamp objects
                return timestamp_value.to_pydatetime()
            elif isinstance(timestamp_value, datetime):
                # Already a datetime object
                return timestamp_value
            else:
                # Fallback to current time
                return datetime.now()
        except:
            return datetime.now()


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


class FormatJSON(beam.DoFn):
    """Format output for writing to files."""

    def process(self, element: UserStaypoints) -> Iterator[str]:
        # Convert to JSON format for output
        output_dict = element.to_dict()
        yield json.dumps(output_dict)


class FormatParquet(beam.DoFn):
    """Format output for Parquet files with partition keys."""

    def process(self, element: UserStaypoints) -> Iterator[Dict[str, Any]]:
        # Convert to dictionary format suitable for Parquet
        yield {
            'user_id': element.user_id,
            'staypoints': [sp.to_dict() for sp in element.staypoints],
            'p1': element.p1,
            'p2': element.p2
        }


class WritePartitionedParquet(beam.DoFn):
    """Write Parquet files with Hive-style partitioning using Beam's file system."""

    def __init__(self, output_path: str):
        self.output_path = output_path

    def process(self, user_staypoints: UserStaypoints):
        # Create Hive-style file path
        p1 = user_staypoints.p1
        p2 = user_staypoints.p2
        file_path = f"{self.output_path}/p1={p1}/p2={p2}/data.parquet"

        # Use Beam's file system to write
        from apache_beam.io.filesystems import FileSystems

        # Convert to Parquet format
        import pyarrow.parquet as pq
        import pyarrow as pa

        # Define the schema to match the existing nested structure
        schema = pa.schema([
            ('user_id', pa.string()),
            ('staypoints', pa.list_(pa.struct([
                ('enter_time', pa.timestamp('us')),
                ('exit_time', pa.timestamp('us')),
                ('lat', pa.float64()),
                ('lng', pa.float64())
            ]))),
            ('p1', pa.string()),
            ('p2', pa.string())
        ])

        # Convert staypoints to list of dictionaries for nested structure
        element = user_staypoints.to_dict()

        # Create Arrow table from single record with explicit schema
        # Convert dict to separate arrays for each column
        arrays = [
            pa.array([element['user_id']]),
            pa.array([element['staypoints']]),
            pa.array([element['p1']]),
            pa.array([element['p2']])
        ]
        table = pa.table(arrays, schema=schema)

        # Write to file using Beam's file system
        with FileSystems.create(file_path) as f:
            pq.write_table(table, f)

        yield file_path


def run_pipeline(argv=None):
    """Main pipeline function."""

    parser = argparse.ArgumentParser()
    parser.add_argument('--input', required=True, help='Input Parquet file path or GCS path')
    parser.add_argument('--output', required=True, help='Output file path')
    parser.add_argument('--output_format', default='json', choices=['json', 'csv', 'hive'],
                       help='Output format (json, csv, or hive)')
    parser.add_argument('--project', help='GCP Project ID')
    parser.add_argument('--region', default='us-central1', help='GCP Region')
    parser.add_argument('--runner', default='DirectRunner', help='Beam runner')
    parser.add_argument('--temp_location', help='Temporary location for Dataflow')
    parser.add_argument('--staging_location', help='Staging location for Dataflow')

    known_args, pipeline_args = parser.parse_known_args(argv)

    # Set up pipeline options
    pipeline_options = PipelineOptions(pipeline_args)

    with beam.Pipeline(options=pipeline_options) as pipeline:
        # Read input data from Parquet files
        trips = (
            pipeline
            | 'ReadTrips' >> ReadFromParquet(known_args.input)
            | 'ParseTripData' >> beam.ParDo(ParseTripData())
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
        if known_args.output_format == 'json':
            output = (
                staypoints
                | 'FormatJSON' >> beam.ParDo(FormatJSON())
                | 'WriteOutput' >> WriteToText(known_args.output, file_name_suffix='.json')
            )
        elif known_args.output_format == 'csv':
            output = (
                staypoints
                | 'FormatCSV' >> beam.Map(lambda x: f"{x.user_id},{x.p1},{x.p2},{json.dumps([sp.to_dict() for sp in x.staypoints])}")
                | 'WriteOutput' >> WriteToText(known_args.output, file_name_suffix='.csv')
            )
        else:  # hive format
            # Group staypoints by user and write to Parquet with Hive partitioning
            output = (
                staypoints
                | 'WritePartitionedParquet' >> beam.ParDo(WritePartitionedParquet(known_args.output))
            )


if __name__ == '__main__':
    logging.getLogger().setLevel(logging.INFO)
    run_pipeline()
