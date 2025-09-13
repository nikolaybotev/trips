#!/usr/bin/env python3
"""
Data models for the trips to staypoints dataflow job.
"""

from datetime import datetime
from typing import Dict, List, Any
from dataclasses import dataclass


@dataclass
class TripData:
    """Data class representing a trip record."""
    user_id: str
    trip_start_time: str
    trip_end_time: str
    start_lat: float
    start_lng: float
    end_lat: float
    end_lng: float

    def to_dict(self) -> Dict[str, Any]:
        return {
            'user_id': self.user_id,
            'trip_start_time': self.trip_start_time,
            'trip_end_time': self.trip_end_time,
            'start_lat': self.start_lat,
            'start_lng': self.start_lng,
            'end_lat': self.end_lat,
            'end_lng': self.end_lng
        }


@dataclass
class StaypointData:
    """Data class representing a staypoint record."""
    enter_time: datetime
    exit_time: datetime
    lat: float
    lng: float

    def to_dict(self) -> Dict[str, Any]:
        return {
            'enter_time': self.enter_time,
            'exit_time': self.exit_time,
            'lat': self.lat,
            'lng': self.lng
        }


@dataclass
class UserStaypoints:
    """Data class representing aggregated staypoints for a user."""
    user_id: str
    staypoints: List[StaypointData]
    p1: str
    p2: str

    def to_dict(self) -> Dict[str, Any]:
        return {
            'user_id': self.user_id,
            'staypoints': [sp.to_dict() for sp in self.staypoints],
            'p1': self.p1,
            'p2': self.p2
        }
