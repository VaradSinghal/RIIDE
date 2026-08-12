"""
GigKavach — Claims & Payouts: Parametric Trigger Engine

Evaluates 5 disruption triggers for a given H3 zone.
Each trigger checks mock environmental data against thresholds and,
if triggered, auto-creates a claim for impacted workers.
"""

import random
import logging
from datetime import datetime

logger = logging.getLogger(__name__)


# ── Trigger Definitions ──

TRIGGERS = {
    "heavy_rainfall": {
        "label": "Heavy Rainfall",
        "threshold": ">40mm in 6-hour window",
        "threshold_value": 40,
        "source": "OpenWeather API",
    },
    "severe_aqi": {
        "label": "Severe AQI",
        "threshold": ">350 for 3+ consecutive hours",
        "threshold_value": 350,
        "source": "AQICN API",
    },
    "extreme_heat": {
        "label": "Extreme Heat",
        "threshold": ">43°C during work hours (8AM-8PM)",
        "threshold_value": 43,
        "source": "OpenWeather API",
    },
    "flooding": {
        "label": "Flood Alert",
        "threshold": "Active IMD flood warning for zone",
        "source": "IMD Alert Feed",
    },
    "civic_disruption": {
        "label": "Civic Disruption",
        "threshold": "Bandh/strike/curfew detected",
        "source": "News + Traffic API",
    },
}


def _severity(value: float, threshold: float, critical: float) -> str:
    """Calculate severity level from moderate → high → critical."""
    if critical == threshold:
        return "moderate"
    ratio = (value - threshold) / (critical - threshold)
    if ratio > 0.7:
        return "critical"
    elif ratio > 0.3:
        return "high"
    return "moderate"


import os
import httpx

RISK_PRICING_URL = os.getenv("RISK_PRICING_URL", "http://risk-pricing:8002")

async def fetch_weather_and_aqi(h3_zone: str, city: str) -> dict:
    """Fetch current environmental data from Risk & Pricing service."""
    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            resp = await client.get(
                f"{RISK_PRICING_URL}/risk/weather/{h3_zone}",
                params={"city": city},
            )
            if resp.status_code == 200:
                return resp.json()
    except Exception as e:
        logger.error(f"Error fetching weather data: {e}")
    
    # Fallback mock data if service is unavailable
    return {
        "weather": {"temperature_c": 32, "rainfall_6hr_mm": 0, "wind_speed_kmh": 10},
        "aqi": {"aqi": 100, "consecutive_hours": 0},
        "flood": {"active_alert": False, "message": "No alerts", "severity": "none"},
        "civic": {"active": False, "description": "All clear", "severity": "none"}
    }


async def evaluate_all_triggers(h3_zone: str, city: str) -> list[dict]:
    """
    Evaluate all 5 parametric triggers for a given zone.
    Returns list of triggered events (may be empty if no triggers active).
    """
    data = await fetch_weather_and_aqi(h3_zone, city)
    weather = data.get("weather", {})
    aqi = data.get("aqi", {})
    flood = data.get("flood", {})
    civic = data.get("civic", {"active": False, "description": "All clear"})

    active = []

    # Trigger 1: Heavy Rainfall (>40mm in 6hrs)
    if weather.get("rainfall_6hr_mm", 0) > 40:
        active.append({
            "trigger_type": "heavy_rainfall",
            "label": "Heavy Rainfall",
            "value": f"{weather['rainfall_6hr_mm']}mm in 6hrs",
            "threshold": ">40mm in 6hrs",
            "severity": _severity(weather["rainfall_6hr_mm"], 40, 80),
            "data": weather,
        })

    # Trigger 2: Severe AQI (>350 for 3+ consecutive hours)
    if aqi.get("aqi", 0) > 350 and aqi.get("consecutive_hours", 0) >= 3:
        active.append({
            "trigger_type": "severe_aqi",
            "label": "Severe AQI",
            "value": f"AQI {aqi['aqi']} for {aqi['consecutive_hours']}hrs",
            "threshold": ">350 for 3+ hours",
            "severity": _severity(aqi["aqi"], 350, 500),
            "data": aqi,
        })

    # Trigger 3: Extreme Heat (>43°C during 8AM-8PM)
    hour = datetime.now().hour
    if weather.get("temperature_c", 0) > 43 and 8 <= hour <= 20:
        active.append({
            "trigger_type": "extreme_heat",
            "label": "Extreme Heat",
            "value": f"{weather['temperature_c']}°C",
            "threshold": ">43°C during work hours",
            "severity": _severity(weather["temperature_c"], 43, 50),
            "data": weather,
        })

    # Trigger 4: Flooding (active IMD alert)
    if flood.get("active", False) or flood.get("active_alert", False):
        active.append({
            "trigger_type": "flooding",
            "label": "Flood Alert",
            "value": flood.get("message", "Active Alert"),
            "threshold": "Active IMD alert",
            "severity": flood.get("severity", "high"),
            "data": flood,
        })

    # Trigger 5: Civic Disruption (bandh/strike/curfew)
    if civic.get("active", False):
        active.append({
            "trigger_type": "civic_disruption",
            "label": "Civic Disruption",
            "value": civic.get("message", "Disruption"),
            "threshold": "Zone closure/bandh",
            "severity": civic.get("severity", "high"),
            "data": civic,
        })

    return active


async def get_trigger_status(h3_zone: str, city: str) -> list[dict]:
    """
    Get current status of all 5 triggers (for dashboard display).
    Always returns all 5, each marked as 'monitoring', 'triggered', or 'safe'.
    """
    data = await fetch_weather_and_aqi(h3_zone, city)
    weather = data.get("weather", {"rainfall_6hr_mm": 0, "temperature_c": 32})
    aqi = data.get("aqi", {"aqi": 100})
    flood = data.get("flood", {"active": False, "active_alert": False, "message": "No alerts"})
    civic = data.get("civic", {"active": False, "description": "All clear"})

    return [
        {
            "trigger_type": "heavy_rainfall",
            "label": "Heavy Rainfall",
            "threshold": ">40mm / 6hrs",
            "current_value": f"{weather['rainfall_6hr_mm']}mm",
            "risk_level": min(weather["rainfall_6hr_mm"] / 60, 1.0),
            "status": "triggered" if weather["rainfall_6hr_mm"] > 40 else "monitoring",
            "source": "OpenWeather API",
        },
        {
            "trigger_type": "severe_aqi",
            "label": "Severe AQI",
            "threshold": ">350 / 3hrs",
            "current_value": f"AQI {aqi['aqi']}",
            "risk_level": min(aqi["aqi"] / 500, 1.0),
            "status": "triggered" if aqi["aqi"] > 350 else "monitoring",
            "source": "AQICN API",
        },
        {
            "trigger_type": "extreme_heat",
            "label": "Extreme Heat",
            "threshold": ">43°C",
            "current_value": f"{weather['temperature_c']}°C",
            "risk_level": max(0, (weather["temperature_c"] - 35) / 15),
            "status": "triggered" if weather["temperature_c"] > 43 else "monitoring",
            "source": "OpenWeather API",
        },
        {
            "trigger_type": "flooding",
            "label": "Flood Alert",
            "threshold": "IMD alert active",
            "current_value": flood["alert_message"] if flood["active_alert"] else "No alerts",
            "risk_level": 0.9 if flood["active_alert"] else 0.0,
            "status": "triggered" if flood["active_alert"] else "safe",
            "source": "IMD Alert Feed",
        },
        {
            "trigger_type": "civic_disruption",
            "label": "Civic Disruption",
            "threshold": "Zone closure",
            "current_value": civic["description"] if civic["active"] else "All clear",
            "risk_level": 0.8 if civic["active"] else 0.0,
            "status": "triggered" if civic["active"] else "safe",
            "source": "News + Traffic API",
        },
    ]
