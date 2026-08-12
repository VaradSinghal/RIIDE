"""
GigKavach — Worker & Earnings: Earnings Aggregator

Aggregates earnings across platforms, computes summary statistics.
"""

from datetime import date, timedelta
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import EarningsLog


async def get_earnings_summary(
    db: AsyncSession,
    worker_id: str,
    days: int = 30,
) -> dict:
    """
    Aggregate earnings for a worker over the last N days.
    Returns per-platform breakdown and totals.
    """
    cutoff = date.today() - timedelta(days=days)

    result = await db.execute(
        select(
            EarningsLog.platform,
            func.sum(EarningsLog.gross_earnings).label("total_earnings"),
            func.sum(EarningsLog.incentives).label("total_incentives"),
            func.sum(EarningsLog.tips).label("total_tips"),
            func.sum(EarningsLog.hours_worked).label("total_hours"),
            func.sum(EarningsLog.orders_completed).label("total_orders"),
            func.count(EarningsLog.id).label("shift_count"),
        )
        .where(EarningsLog.worker_id == worker_id)
        .where(EarningsLog.date >= cutoff)
        .group_by(EarningsLog.platform)
    )
    rows = result.all()

    platforms = {}
    grand_total = 0
    grand_hours = 0
    grand_orders = 0

    for row in rows:
        earnings = float(row.total_earnings or 0)
        hours = float(row.total_hours or 0)
        platforms[row.platform] = {
            "total_earnings": earnings,
            "total_incentives": float(row.total_incentives or 0),
            "total_tips": float(row.total_tips or 0),
            "total_hours": hours,
            "total_orders": int(row.total_orders or 0),
            "shift_count": row.shift_count,
            "avg_hourly": round(earnings / hours, 2) if hours > 0 else 0,
        }
        grand_total += earnings
        grand_hours += hours
        grand_orders += int(row.total_orders or 0)

    return {
        "worker_id": worker_id,
        "period_days": days,
        "platforms": platforms,
        "totals": {
            "gross_earnings": round(grand_total, 2),
            "total_hours": round(grand_hours, 1),
            "total_orders": grand_orders,
            "avg_daily": round(grand_total / days, 2) if days > 0 else 0,
            "avg_weekly": round(grand_total / days * 7, 2) if days > 0 else 0,
            "avg_hourly": round(grand_total / grand_hours, 2) if grand_hours > 0 else 0,
        },
    }


async def get_daily_earnings(
    db: AsyncSession,
    worker_id: str,
    days: int = 14,
) -> list[dict]:
    """Get daily earnings breakdown for charting."""
    cutoff = date.today() - timedelta(days=days)

    result = await db.execute(
        select(
            EarningsLog.date,
            func.sum(EarningsLog.gross_earnings).label("earnings"),
            func.sum(EarningsLog.hours_worked).label("hours"),
            func.sum(EarningsLog.orders_completed).label("orders"),
        )
        .where(EarningsLog.worker_id == worker_id)
        .where(EarningsLog.date >= cutoff)
        .group_by(EarningsLog.date)
        .order_by(EarningsLog.date)
    )

    return [
        {
            "date": str(row.date),
            "earnings": float(row.earnings or 0),
            "hours": float(row.hours or 0),
            "orders": int(row.orders or 0),
        }
        for row in result.all()
    ]
