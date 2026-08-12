"""
GigKavach — Trust & Fraud: Location Verifier (25 pts)

Checks whether the worker was actually in the claimed zone.
Mock implementation — real version would use Play Integrity API,
GPS trail analysis, and sensor-fusion physics checks.
"""

import math
from app.services.confidence_scorer import DimensionResult


def verify_location(claim_data: dict) -> DimensionResult:
    """
    Verify location integrity (25 points max).

    Mock checks:
    - GPS coordinates are within the claimed zone
    - Movement speed is physically plausible
    - No mock-location flags (always clean in mock)
    """
    max_points = 25
    location = claim_data.get("location", {})
    lat = location.get("lat", 0)
    lon = location.get("lon", 0)

    # Check if coordinates are reasonable for India
    if 6.0 <= lat <= 37.0 and 68.0 <= lon <= 98.0:
        # Simulate GPS trail check
        last_lat = claim_data.get("last_location", {}).get("lat", lat)
        last_lon = claim_data.get("last_location", {}).get("lon", lon)
        time_diff = claim_data.get("time_diff_seconds", 300)

        # Calculate distance
        distance_km = _haversine(lat, lon, last_lat, last_lon)
        speed_kmh = (distance_km / max(time_diff, 1)) * 3600

        if speed_kmh > 200:
            # Impossible speed — likely GPS spoofing
            return DimensionResult(
                dimension="Location Integrity",
                max_points=max_points,
                awarded_points=5,
                passed=False,
                detail=f"Suspicious movement: {speed_kmh:.0f} km/h (physically impossible)",
            )
        elif speed_kmh > 80:
            # High speed — possible but needs review
            return DimensionResult(
                dimension="Location Integrity",
                max_points=max_points,
                awarded_points=15,
                passed=False,
                detail=f"High movement speed: {speed_kmh:.0f} km/h (review needed)",
            )
        else:
            return DimensionResult(
                dimension="Location Integrity",
                max_points=max_points,
                awarded_points=25,
                passed=True,
                detail=f"Location verified: movement {speed_kmh:.1f} km/h (plausible)",
            )
    elif lat == 0 and lon == 0:
        # No location data provided — partial credit
        return DimensionResult(
            dimension="Location Integrity",
            max_points=max_points,
            awarded_points=15,
            passed=False,
            detail="No GPS data available — partial verification",
        )
    else:
        return DimensionResult(
            dimension="Location Integrity",
            max_points=max_points,
            awarded_points=0,
            passed=False,
            detail=f"Coordinates outside India: ({lat}, {lon})",
        )


def _haversine(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """Calculate distance in km between two lat/lon points."""
    R = 6371  # Earth radius in km
    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)
    a = math.sin(dlat / 2) ** 2 + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(dlon / 2) ** 2
    return R * 2 * math.asin(math.sqrt(a))
