"""
GigKavach — Risk & Pricing: Risk Routes
"""

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from app.database import get_db
from app.services.risk_engine import get_zone_risk, get_city_zones
from app.services.weather_provider import weather_provider

router = APIRouter()


@router.get("/zone/{h3_index}")
async def zone_risk(h3_index: str, db: AsyncSession = Depends(get_db)):
    """Get risk score for an H3 zone."""
    return await get_zone_risk(db, h3_index)


@router.get("/city/{city}")
async def city_heatmap(city: str, db: AsyncSession = Depends(get_db)):
    """Get all zone risk scores for a city (heatmap data)."""
    zones = await get_city_zones(db, city)
    return {"city": city, "zones": zones, "total": len(zones)}


@router.get("/weather/{h3_index}")
async def zone_weather(h3_index: str, city: str = "Chennai"):
    """Get current weather data for a zone."""
    weather = weather_provider.get_weather(h3_index, city)
    aqi = weather_provider.get_aqi(h3_index, city)
    flood = weather_provider.get_flood_alerts(h3_index, city)
    return {
        "h3_index": h3_index,
        "weather": weather.__dict__,
        "aqi": aqi.__dict__,
        "flood": flood.__dict__,
    }
