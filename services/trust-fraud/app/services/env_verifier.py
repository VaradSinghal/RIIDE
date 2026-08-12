"""
GigKavach — Trust & Fraud: Environmental Verifier (30 pts)

Checks whether a real disruption occurred at the claimed time and location.
Compares trigger data against known environmental conditions.
"""

from app.services.confidence_scorer import DimensionResult


def verify_environment(claim_data: dict) -> DimensionResult:
    """
    Verify environmental disruption (30 points max).

    Checks:
    - Trigger type matches known disruption patterns
    - Environmental data supports the claim
    - Cross-source agreement (mock: always agrees for now)
    """
    max_points = 30
    trigger_type = claim_data.get("trigger_type", "unknown")
    trigger_data = claim_data.get("trigger_data", {})

    # Check if the trigger data contains supporting evidence
    if trigger_type == "heavy_rainfall":
        rainfall = trigger_data.get("rainfall_6hr_mm", 0)
        if rainfall > 40:
            return DimensionResult(
                dimension="Environmental Confirmation",
                max_points=max_points,
                awarded_points=30,
                passed=True,
                detail=f"Rainfall confirmed: {rainfall}mm in 6hrs (threshold: 40mm)",
            )
        else:
            return DimensionResult(
                dimension="Environmental Confirmation",
                max_points=max_points,
                awarded_points=int(min(rainfall / 40 * 20, 20)),
                passed=False,
                detail=f"Rainfall below threshold: {rainfall}mm (need >40mm)",
            )

    elif trigger_type == "severe_aqi":
        aqi = trigger_data.get("aqi", 0)
        hours = trigger_data.get("consecutive_hours", 0)
        if aqi > 350 and hours >= 3:
            return DimensionResult(
                dimension="Environmental Confirmation",
                max_points=max_points,
                awarded_points=30,
                passed=True,
                detail=f"AQI confirmed: {aqi} for {hours}hrs (threshold: >350 for 3+hrs)",
            )
        else:
            return DimensionResult(
                dimension="Environmental Confirmation",
                max_points=max_points,
                awarded_points=10,
                passed=False,
                detail=f"AQI conditions insufficient: AQI={aqi}, hours={hours}",
            )

    elif trigger_type == "extreme_heat":
        temp = trigger_data.get("temperature_c", 0)
        if temp > 43:
            return DimensionResult(
                dimension="Environmental Confirmation",
                max_points=max_points,
                awarded_points=30,
                passed=True,
                detail=f"Temperature confirmed: {temp}°C (threshold: >43°C)",
            )
        else:
            return DimensionResult(
                dimension="Environmental Confirmation",
                max_points=max_points,
                awarded_points=int(min((temp - 35) / 8 * 20, 20)) if temp > 35 else 0,
                passed=False,
                detail=f"Temperature below threshold: {temp}°C (need >43°C)",
            )

    elif trigger_type == "flooding":
        if trigger_data.get("active_alert", False):
            return DimensionResult(
                dimension="Environmental Confirmation",
                max_points=max_points,
                awarded_points=30,
                passed=True,
                detail="Active flood alert confirmed from IMD",
            )

    elif trigger_type == "civic_disruption":
        if trigger_data.get("active", False):
            return DimensionResult(
                dimension="Environmental Confirmation",
                max_points=max_points,
                awarded_points=28,
                passed=True,
                detail="Civic disruption confirmed from traffic/news feeds",
            )

    # Default: partial credit
    return DimensionResult(
        dimension="Environmental Confirmation",
        max_points=max_points,
        awarded_points=15,
        passed=False,
        detail=f"Insufficient environmental data for trigger type '{trigger_type}'",
    )
