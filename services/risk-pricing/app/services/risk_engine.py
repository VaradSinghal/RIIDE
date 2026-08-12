"""
GigKavach — Risk & Pricing: H3-based Risk Engine

Assigns each H3 hex zone a risk score (0-100) using:
  - Historical weather events (30%)
  - Terrain & drainage (25%)
  - Historical claims data (25%)
  - Real-time conditions (20%)
"""

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.models import H3Zone
from app.services.weather_provider import weather_provider


async def get_zone_risk(db: AsyncSession, h3_index: str) -> dict:
    """Get risk score for an H3 zone."""
    result = await db.execute(
        select(H3Zone).where(H3Zone.h3_index == h3_index)
    )
    zone = result.scalar_one_or_none()

    if zone:
        return {
            "h3_index": zone.h3_index,
            "city": zone.city,
            "zone_name": zone.zone_name,
            "risk_score": float(zone.risk_score),
            "risk_label": zone.risk_label,
            "flood_prone": zone.flood_prone,
            "weather_risk_factor": float(zone.weather_risk_factor),
        }

    # Default for unknown zones
    return {
        "h3_index": h3_index,
        "city": "Unknown",
        "zone_name": None,
        "risk_score": 50.0,
        "risk_label": "Moderate",
        "flood_prone": False,
        "weather_risk_factor": 0.3,
    }


async def get_city_zones(db: AsyncSession, city: str) -> list[dict]:
    """Get all zones for a city (for heatmap display)."""
    result = await db.execute(
        select(H3Zone).where(H3Zone.city == city).order_by(H3Zone.risk_score.desc())
    )
    zones = result.scalars().all()
    return [
        {
            "h3_index": z.h3_index,
            "city": z.city,
            "zone_name": z.zone_name,
            "risk_score": float(z.risk_score),
            "risk_label": z.risk_label,
            "flood_prone": z.flood_prone,
        }
        for z in zones
    ]


def compute_risk_score(
    historical_weather: float = 0.5,
    terrain_drainage: float = 0.5,
    historical_claims: float = 0.5,
    realtime_conditions: float = 0.5,
) -> float:
    """
    Compute zone risk score (0-100) from four weighted inputs.
    Each input is 0-1 (normalized risk factor).

    Weights:
      Historical weather: 30%
      Terrain & drainage: 25%
      Historical claims: 25%
      Real-time conditions: 20%
    """
    score = (
        historical_weather * 0.30 +
        terrain_drainage * 0.25 +
        historical_claims * 0.25 +
        realtime_conditions * 0.20
    ) * 100

    return round(min(max(score, 0), 100), 2)


def risk_label_from_score(score: float) -> str:
    """Map score to human-readable label."""
    if score >= 70:
        return "High"
    elif score >= 40:
        return "Moderate"
    return "Low"
