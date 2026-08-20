"""
GigKavach — Risk & Pricing: Premium Calculator

Weekly Premium = Base Premium + Zone Risk Adjustment + Weather Forecast Adjustment
Coverage Ceiling = 70% × Average Weekly Earnings

Rule-based for now, structured so a GLM/Ridge model can replace it.
"""

from decimal import Decimal
from datetime import datetime, timedelta
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import PremiumQuote
from app.services.weather_provider import weather_provider


PLAN_TIERS = {
    "basic": {"base_rate": 25, "coverage_pct": 50, "triggers": 3},
    "standard": {"base_rate": 45, "coverage_pct": 70, "triggers": 5},
    "premium": {"base_rate": 65, "coverage_pct": 85, "triggers": 5},
}


from app.services.ai_underwriter import ai_underwriter

async def calculate_premium(
    db: AsyncSession,
    worker_id: str,
    h3_zone: str,
    city: str,
    avg_weekly_income: float,
    zone_risk_score: float = 50.0,
    plan_tier: str = "standard",
    experience_weeks: int = 0,
    claim_rate: float = 0.0,
    vehicle_type: str = "bike",
    worker_age: int = 25,
    verified_daily_hours: float = 8.0,
    verified_daily_income: float = 500.0,
) -> dict:
    """
    Calculate personalized weekly premium using ML model and persist the quote.
    """
    tier = PLAN_TIERS.get(plan_tier, PLAN_TIERS["standard"])
    base_rate = tier["base_rate"]

    weather = weather_provider.get_weather(h3_zone, city)
    weather_risk = _compute_weather_risk(weather)

    # Use AI Model for dynamic premium calculation
    ai_explanation = ai_underwriter.predict_premium(
        zone_risk=zone_risk_score,
        weather_risk=weather_risk,
        experience_weeks=experience_weeks,
        claim_rate=claim_rate,
        vehicle_type=vehicle_type,
        worker_age=worker_age,
        verified_daily_hours=verified_daily_hours,
        verified_daily_income=verified_daily_income
    )
    
    weekly_premium = ai_explanation["predicted_premium"]
    coverage_ceiling = round(avg_weekly_income * tier["coverage_pct"] / 100, 2)

    # Persist the quote
    now = datetime.utcnow()
    quote = PremiumQuote(
        worker_id=worker_id,
        h3_zone=h3_zone,
        base_premium=base_rate,
        zone_risk_adjustment=round((zone_risk_score/100)*20, 2), # Legacy compat
        weather_forecast_adjustment=round(weather_risk*15, 2),  # Legacy compat
        weekly_premium=weekly_premium,
        coverage_ceiling=coverage_ceiling,
        vehicle_type=vehicle_type,
        experience_weeks=experience_weeks,
        worker_age=worker_age,
        historical_claim_rate=claim_rate,
        valid_from=now,
        valid_until=now + timedelta(days=7),
    )
    db.add(quote)
    await db.flush()

    return {
        "worker_id": worker_id,
        "plan_tier": plan_tier,
        "weekly_premium": weekly_premium,
        "coverage_percentage": tier["coverage_pct"],
        "coverage_ceiling": coverage_ceiling,
        "triggers_covered": tier["triggers"],
        "factors": {
            "zone_risk_score": zone_risk_score,
            "weather_risk": weather_risk,
            "experience_weeks": experience_weeks,
            "claim_rate": claim_rate,
            "vehicle_type": vehicle_type,
            "worker_age": worker_age,
        },
        "valid_from": now.isoformat(),
        "valid_until": (now + timedelta(days=7)).isoformat(),
        "model_used": "random_forest_regressor",
        "ai_reasoning": ai_explanation
    }


def _compute_weather_risk(weather) -> float:
    """
    Compute weather risk factor (0-1) from current conditions.
    Higher = more dangerous.
    """
    risk = 0.0

    # Rainfall contribution
    if weather.rainfall_6hr_mm > 40:
        risk += 0.4
    elif weather.rainfall_6hr_mm > 20:
        risk += 0.2

    # Temperature contribution
    if weather.temperature_c > 43:
        risk += 0.3
    elif weather.temperature_c > 38:
        risk += 0.1

    # Wind contribution
    if weather.wind_speed_kmh > 50:
        risk += 0.2
    elif weather.wind_speed_kmh > 30:
        risk += 0.1

    return min(risk, 1.0)
