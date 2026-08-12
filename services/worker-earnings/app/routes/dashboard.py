"""
GigKavach — Worker & Earnings: Dashboard/Workers Routes
"""

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession
from app.database import get_db
from app.models import Worker

router = APIRouter()


@router.get("/")
async def list_workers(
    city: str = None,
    limit: int = 50,
    offset: int = 0,
    db: AsyncSession = Depends(get_db),
):
    """List workers with optional city filter."""
    query = select(Worker)
    if city:
        query = query.where(Worker.city == city)
    query = query.order_by(Worker.created_at.desc()).limit(limit).offset(offset)

    result = await db.execute(query)
    workers = result.scalars().all()

    count_q = select(func.count(Worker.id))
    if city:
        count_q = count_q.where(Worker.city == city)
    total = (await db.execute(count_q)).scalar()

    return {
        "workers": [_worker_dict(w) for w in workers],
        "total": total,
    }


@router.get("/{worker_id}")
async def get_worker(worker_id: str, db: AsyncSession = Depends(get_db)):
    """Get a single worker profile."""
    result = await db.execute(select(Worker).where(Worker.worker_id == worker_id))
    worker = result.scalar_one_or_none()
    if not worker:
        raise HTTPException(status_code=404, detail=f"Worker {worker_id} not found")
    return _worker_dict(worker)


def _worker_dict(w: Worker) -> dict:
    return {
        "worker_id": w.worker_id,
        "name": w.name,
        "phone": w.phone,
        "city": w.city,
        "h3_zone": w.h3_zone,
        "primary_platform": w.primary_platform,
        "secondary_platform": w.secondary_platform,
        "vehicle_type": w.vehicle_type,
        "avg_daily_hours": float(w.avg_daily_hours) if w.avg_daily_hours else None,
        "experience_weeks": w.experience_weeks,
        "avg_daily_income": float(w.avg_daily_income) if w.avg_daily_income else None,
        "avg_weekly_income": float(w.avg_weekly_income) if w.avg_weekly_income else None,
        "created_at": w.created_at.isoformat() if w.created_at else None,
    }
