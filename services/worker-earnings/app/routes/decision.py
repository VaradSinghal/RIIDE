"""
GigKavach — Worker & Earnings: Decision Routes
"""

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from app.database import get_db
from app.services.decision_engine import compute_decision_score

router = APIRouter()


@router.get("/score/{worker_id}")
async def get_decision_score(
    worker_id: str,
    h3_zone: str = "872a10d83ffffff",
    city: str = "Chennai",
    db: AsyncSession = Depends(get_db),
):
    """
    Compute the GO / CAUTION / STAY_HOME decision score.

    Decision Score = (Demand × 0.35) + (Weather Safety × 0.35)
                   + (Insurance Coverage × 0.20) + (Historical Stability × 0.10)
    """
    result = await compute_decision_score(db, worker_id, h3_zone, city)
    await db.commit()
    return result
