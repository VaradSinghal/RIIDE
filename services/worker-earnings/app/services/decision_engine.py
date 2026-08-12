"""
GigKavach — Worker & Earnings: Decision Engine

Decision Score = (Demand × 0.35) + (Weather Safety × 0.35)
               + (Insurance Coverage × 0.20) + (Historical Stability × 0.10)

65-100 → GO
35-64  → CAUTION
0-34   → STAY_HOME
"""

import random
import httpx
import os
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import EarningsLog, DecisionScore, Worker


RISK_PRICING_URL = os.getenv("RISK_PRICING_URL", "http://risk-pricing:8002")


async def compute_decision_score(
    db: AsyncSession,
    worker_id: str,
    h3_zone: str,
    city: str = "Chennai",
) -> dict:
    """
    Compute the GO / CAUTION / STAY_HOME decision score.

    Weights:
      Demand: 35%
      Weather Safety: 35%
      Insurance Coverage: 20%
      Historical Stability: 10%
    """
    # 1. Demand score — from recent earnings density
    demand = await _compute_demand_score(db, h3_zone)

    # 2. Weather safety — from Risk & Pricing service
    weather_safety = await _fetch_weather_safety(h3_zone, city)

    # 3. Insurance coverage — mock for now
    insurance_coverage = 70.0  # percentage

    # 4. Historical stability — from earnings variance
    stability = await _compute_stability_score(db, worker_id)

    # Weighted composite
    composite = (
        demand * 0.35 +
        weather_safety * 0.35 +
        insurance_coverage * 0.20 +
        stability * 0.10
    )
    composite = round(min(max(composite, 0), 100), 1)

    # Recommendation
    if composite >= 65:
        recommendation = "GO"
    elif composite >= 35:
        recommendation = "CAUTION"
    else:
        recommendation = "STAY_HOME"

    # Persist
    score = DecisionScore(
        worker_id=worker_id,
        h3_zone=h3_zone,
        demand_score=round(demand, 2),
        weather_safety_score=round(weather_safety, 2),
        insurance_coverage_score=round(insurance_coverage, 2),
        historical_stability_score=round(stability, 2),
        composite_score=composite,
        recommendation=recommendation,
    )
    db.add(score)
    await db.flush()

    return {
        "worker_id": worker_id,
        "h3_zone": h3_zone,
        "composite_score": composite,
        "recommendation": recommendation,
        "components": {
            "demand": {"score": round(demand, 2), "weight": 0.35},
            "weather_safety": {"score": round(weather_safety, 2), "weight": 0.35},
            "insurance_coverage": {"score": round(insurance_coverage, 2), "weight": 0.20},
            "historical_stability": {"score": round(stability, 2), "weight": 0.10},
        },
    }


async def _compute_demand_score(db: AsyncSession, h3_zone: str) -> float:
    """Estimate demand from earnings density. Mock + real data hybrid."""
    # For now: simulated demand based on time patterns
    import datetime
    hour = datetime.datetime.now().hour
    if 11 <= hour <= 14 or 18 <= hour <= 22:
        return random.uniform(65, 90)  # Lunch/dinner rush
    elif 8 <= hour <= 10 or 15 <= hour <= 17:
        return random.uniform(40, 65)  # Moderate
    else:
        return random.uniform(15, 40)  # Off-peak


async def _fetch_weather_safety(h3_zone: str, city: str) -> float:
    """Fetch weather safety score from Risk & Pricing service."""
    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            resp = await client.get(
                f"{RISK_PRICING_URL}/risk/weather/{h3_zone}",
                params={"city": city},
            )
            if resp.status_code == 200:
                data = resp.json()
                weather = data.get("weather", {})
                temp = weather.get("temperature_c", 32)
                rain = weather.get("rainfall_6hr_mm", 0)

                # Convert to safety score (100 = perfectly safe)
                safety = 100
                if rain > 40:
                    safety -= 50
                elif rain > 20:
                    safety -= 20
                if temp > 43:
                    safety -= 40
                elif temp > 38:
                    safety -= 15
                return max(safety, 0)
    except Exception:
        pass

    return random.uniform(50, 85)  # Fallback


async def _compute_stability_score(db: AsyncSession, worker_id: str) -> float:
    """Compute income stability from earnings variance."""
    result = await db.execute(
        select(
            func.avg(EarningsLog.gross_earnings).label("avg"),
            func.stddev(EarningsLog.gross_earnings).label("std"),
            func.count(EarningsLog.id).label("count"),
        ).where(EarningsLog.worker_id == worker_id)
    )
    row = result.one()

    if row.count and row.count > 1 and row.avg and row.std:
        cv = float(row.std) / float(row.avg)  # Coefficient of variation
        # Lower CV = more stable = higher score
        stability = max(0, 100 - cv * 100)
        return min(stability, 100)

    return 60.0  # Default for new workers
