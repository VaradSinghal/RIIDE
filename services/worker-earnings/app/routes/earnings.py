"""
GigKavach — Worker & Earnings: Earnings Routes
"""

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from app.database import get_db
from app.services.earnings_aggregator import get_earnings_summary, get_daily_earnings
from app.services.boost_engine import boost_engine

router = APIRouter()


@router.get("/summary/{worker_id}")
async def earnings_summary(worker_id: str, days: int = 30, db: AsyncSession = Depends(get_db)):
    """Get aggregated earnings summary for a worker."""
    return await get_earnings_summary(db, worker_id, days)


@router.get("/daily/{worker_id}")
async def daily_earnings(worker_id: str, days: int = 14, db: AsyncSession = Depends(get_db)):
    """Get daily earnings breakdown for charting."""
    data = await get_daily_earnings(db, worker_id, days)
    return {"worker_id": worker_id, "days": days, "daily": data}


@router.get("/boost")
async def boost_recommendations(city: str = "Chennai", current_zone: str = "Adyar", n: int = 3):
    """Get top-N zone recommendations for earnings boost."""
    recs = boost_engine.predict_top_zones(city, current_zone, n)
    return {
        "city": city,
        "current_zone": current_zone,
        "recommendations": [
            {
                "zone_name": r.zone_name,
                "h3_index": r.h3_index,
                "expected_hourly": r.expected_hourly,
                "boost_pct": r.boost_pct,
                "reason": r.reason,
                "confidence": r.confidence,
            }
            for r in recs
        ],
    }
