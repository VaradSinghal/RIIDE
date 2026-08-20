import datetime
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from pydantic import BaseModel
from typing import List

from app.database import get_db
from app.models import Worker, EarningsLog

router = APIRouter()

class WorkHistory(BaseModel):
    date: str
    hours_worked: float
    orders_completed: int
    gross_earnings: float

class SyncPlatformRequest(BaseModel):
    worker_id: str
    platform: str
    avg_daily_hours: float
    avg_daily_income: float
    history: List[WorkHistory]

@router.post("/sync")
async def sync_platform_data(req: SyncPlatformRequest, db: AsyncSession = Depends(get_db)):
    """Receives verified historical earnings data from the gateway and saves it."""
    
    # Update or insert Worker
    stmt = select(Worker).where(Worker.worker_id == req.worker_id)
    result = await db.execute(stmt)
    worker = result.scalar_one_or_none()
    
    if not worker:
        # Create a new worker profile if it doesn't exist yet
        worker = Worker(
            worker_id=req.worker_id,
            name="Unknown",  # This would normally be synced from KYC service
            city="Chennai",
            h3_zone="unknown",
            primary_platform=req.platform,
            avg_daily_hours=req.avg_daily_hours,
            avg_daily_income=req.avg_daily_income,
            is_income_verified=True,
            verified_platform=req.platform
        )
        db.add(worker)
    else:
        # Update existing worker
        worker.avg_daily_hours = req.avg_daily_hours
        worker.avg_daily_income = req.avg_daily_income
        worker.is_income_verified = True
        worker.verified_platform = req.platform
        
    # We could insert the history into EarningsLog here.
    # For now, we will just insert the most recent records if they don't exist.
    # A real system would upsert these using the date constraint.
    for h in req.history:
        try:
            log_date = datetime.date.fromisoformat(h.date[:10])
        except ValueError:
            continue
            
        # Simplistic check if log exists for this date and platform
        stmt = select(EarningsLog).where(
            EarningsLog.worker_id == req.worker_id,
            EarningsLog.platform == req.platform,
            EarningsLog.date == log_date
        )
        existing = await db.execute(stmt)
        if not existing.scalar_one_or_none():
            log = EarningsLog(
                worker_id=req.worker_id,
                platform=req.platform,
                date=log_date,
                hours_worked=h.hours_worked,
                orders_completed=h.orders_completed,
                gross_earnings=h.gross_earnings
            )
            db.add(log)
            
    await db.commit()
    
    return {"status": "success", "message": f"Synced {len(req.history)} records"}
