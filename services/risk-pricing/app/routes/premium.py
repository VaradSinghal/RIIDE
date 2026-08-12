"""
GigKavach — Risk & Pricing: Premium Routes
"""

from fastapi import APIRouter, Depends
from pydantic import BaseModel
from typing import Optional
from sqlalchemy.ext.asyncio import AsyncSession
from app.database import get_db
from app.services.premium_calculator import calculate_premium

router = APIRouter()


class PremiumRequest(BaseModel):
    worker_id: str
    h3_zone: str
    city: str = "Chennai"
    avg_weekly_income: float = 4200.0
    zone_risk_score: float = 50.0
    plan_tier: str = "standard"
    experience_weeks: int = 0
    claim_rate: float = 0.0
    vehicle_type: str = "bike"
    worker_age: int = 25


@router.post("/calculate")
async def calc_premium(req: PremiumRequest, db: AsyncSession = Depends(get_db)):
    """Calculate personalized weekly premium for a worker."""
    result = await calculate_premium(
        db=db,
        worker_id=req.worker_id,
        h3_zone=req.h3_zone,
        city=req.city,
        avg_weekly_income=req.avg_weekly_income,
        zone_risk_score=req.zone_risk_score,
        plan_tier=req.plan_tier,
        experience_weeks=req.experience_weeks,
        claim_rate=req.claim_rate,
        vehicle_type=req.vehicle_type,
        worker_age=req.worker_age,
    )
    await db.commit()
    return result
