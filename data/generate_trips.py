#!/usr/bin/env python3
"""
Script to generate a CSV with a million random trips for users.
Each user has an average of 3 trips per day with 1-20 trips per day range.
Trip times are within a 1-month range.
"""

import csv
import uuid
import random
import argparse
from datetime import datetime, timedelta
from typing import List, Tuple


def generate_user_id() -> str:
    """Generate a random UUID v4 for user_id."""
    return str(uuid.uuid4())


def generate_random_coordinates() -> Tuple[float, float]:
    """Generate random latitude and longitude coordinates."""
    # Generate coordinates within reasonable bounds (roughly global coverage)
    lat = random.uniform(-90, 90)
    lng = random.uniform(-180, 180)
    return lat, lng


def generate_trip_times(start_date: datetime, end_date: datetime, earliest_start: datetime = None) -> Tuple[str, str]:
    """Generate trip start and end times within the given date range."""
    if earliest_start is None:
        earliest_start = start_date

    # Ensure earliest_start is not before start_date
    earliest_start = max(earliest_start, start_date)

    # Generate random start time between earliest_start and end_date
    time_diff = end_date - earliest_start
    if time_diff.total_seconds() <= 0:
        # If no time available, use the earliest possible time
        trip_start = earliest_start
    else:
        random_seconds = random.randint(0, int(time_diff.total_seconds()))
        trip_start = earliest_start + timedelta(seconds=random_seconds)

    # Generate end time (trip duration between 5 minutes and 4 hours)
    trip_duration_minutes = random.randint(5, 240)
    trip_end = trip_start + timedelta(minutes=trip_duration_minutes)

    # Convert to ISO format timestamps
    start_timestamp = trip_start.isoformat() + 'Z'
    end_timestamp = trip_end.isoformat() + 'Z'

    return start_timestamp, end_timestamp


def generate_trips_for_user(user_id: str, start_date: datetime, end_date: datetime):
    """Generate trips for a single user based on the specified distribution."""
    # Calculate number of days in the range
    days_in_range = (end_date - start_date).days

    # Generate trips for each day
    for day_offset in range(days_in_range):
        current_date = start_date + timedelta(days=day_offset)
        next_date = current_date + timedelta(days=1)

        # Generate number of trips for this day (1-20, average 3)
        # Use a weighted random selection to approximate Poisson distribution
        # Create weights that favor values around 3
        weights = [0.1, 0.2, 0.3, 0.25, 0.15, 0.1, 0.05, 0.02, 0.01, 0.005, 0.002, 0.001, 0.0005, 0.0002, 0.0001, 0.00005, 0.00002, 0.00001, 0.000005, 0.000002]
        trips_today = max(1, min(20, random.choices(range(1, 21), weights=weights)[0]))

        # Track the latest trip end time to ensure sequential trips
        latest_trip_end = current_date

        for _ in range(trips_today):
            trip_start_time, trip_end_time = generate_trip_times(current_date, next_date, latest_trip_end)
            start_lat, start_lng = generate_random_coordinates()
            end_lat, end_lng = generate_random_coordinates()

            trip = {
                'user_id': user_id,
                'trip_start_time': trip_start_time,
                'trip_end_time': trip_end_time,
                'start_lat': start_lat,
                'start_lng': start_lng,
                'end_lat': end_lat,
                'end_lng': end_lng
            }
            yield trip

            # Update latest trip end time for next trip
            trip_end_datetime = datetime.fromisoformat(trip_end_time.replace('Z', '+00:00'))
            # Convert to naive datetime for comparison
            trip_end_naive = trip_end_datetime.replace(tzinfo=None)
            latest_trip_end = max(latest_trip_end, trip_end_naive)


def generate_all_trips(total_trips: int = 1000000):
    """Generate all trips across all users as a generator."""

    # Define 1-month range (30 days)
    end_date = datetime.now()
    start_date = end_date - timedelta(days=30)

    print(f"Generating {total_trips:,} trips from {start_date.strftime('%Y-%m-%d')} to {end_date.strftime('%Y-%m-%d')}")

    # Calculate approximate number of users needed
    # Average 3 trips per day * 30 days = 90 trips per user
    estimated_users = total_trips // 90

    print(f"Estimated users needed: {estimated_users:,}")

    current_trip_count = 0
    user_count = 0

    while current_trip_count < total_trips:
        user_id = generate_user_id()

        # Generate trips for this user one by one
        for trip in generate_trips_for_user(user_id, start_date, end_date):
            if current_trip_count >= total_trips:
                break

            yield trip
            current_trip_count += 1

        user_count += 1

        if user_count % 1000 == 0:
            print(f"Generated {current_trip_count:,} trips from {user_count:,} users...")

    print(f"Final: {current_trip_count:,} trips from {user_count:,} users")


def write_csv(trip_generator, filename: str = 'trips.csv'):
    """Write trips from a generator to CSV file."""
    fieldnames = ['user_id', 'trip_start_time', 'trip_end_time', 'start_lat', 'start_lng', 'end_lat', 'end_lng']

    print(f"Writing trips to {filename}...")

    with open(filename, 'w', newline='', encoding='utf-8') as csvfile:
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        writer.writeheader()

        trip_count = 0
        for trip in trip_generator:
            writer.writerow(trip)
            trip_count += 1

            if trip_count % 100000 == 0:
                print(f"Written {trip_count:,} trips...")

    print(f"Successfully wrote {trip_count:,} trips to {filename}")


def main():
    """Main function to generate and save trips."""
    parser = argparse.ArgumentParser(description='Generate random trips CSV file')
    parser.add_argument('--trips', '-t', type=int, default=1000000,
                       help='Number of trips to generate (default: 1000000)')
    parser.add_argument('--output', '-o', type=str, default='trips.csv',
                       help='Output CSV filename (default: trips.csv)')

    args = parser.parse_args()

    print(f"Starting trip generation...")
    print(f"Generating {args.trips:,} trips to {args.output}")

    # Generate trips as a generator
    trip_generator = generate_all_trips(args.trips)

    # Write trips to CSV from the generator
    write_csv(trip_generator, args.output)

    print("Trip generation completed!")


if __name__ == "__main__":
    main()
