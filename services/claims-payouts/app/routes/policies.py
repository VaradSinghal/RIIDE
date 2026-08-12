"""
GigKavach — Claims & Payouts: Policies Routes
"""

import uuid
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models import Policy
from app.schemas import (
    PolicyCreateRequest, PolicyResponse, PolicyListResponse,
)

router = APIRouter()


@router.post("/", response_model=PolicyResponse)
async def create_policy(req: PolicyCreateRequest, db: AsyncSession = Depends(get_db)):
    """Create a new insurance policy."""
    policy_id = f"POL-{uuid.uuid4().hex[:8].upper()}"
    policy = Policy(
        policy_id=policy_id,
        worker_id=req.worker_id,
        h3_zone=req.h3_zone,
        tier=req.tier,
        weekly_premium=req.weekly_premium,
        coverage_percentage=req.coverage_percentage,
        coverage_ceiling=req.coverage_ceiling,
        start_date=req.start_date,
        end_date=req.end_date,
        status="active",
    )
    db.add(policy)
    await db.commit()

    return _policy_to_response(policy)


@router.get("/", response_model=PolicyListResponse)
async def list_policies(
    worker_id: str = None,
    status: str = None,
    limit: int = 50,
    offset: int = 0,
    db: AsyncSession = Depends(get_db),
):
    """List policies with optional filters."""
    query = select(Policy)
    count_query = select(func.count(Policy.id))

    if worker_id:
        query = query.where(Policy.worker_id == worker_id)
        count_query = count_query.where(Policy.worker_id == worker_id)
    if status:
        query = query.where(Policy.status == status)
        count_query = count_query.where(Policy.status == status)

    query = query.order_by(Policy.created_at.desc()).limit(limit).offset(offset)
    result = await db.execute(query)
    policies = result.scalars().all()

    total_result = await db.execute(count_query)
    total = total_result.scalar()

    return PolicyListResponse(
        policies=[_policy_to_response(p) for p in policies],
        total=total,
    )


@router.get("/{policy_id}", response_model=PolicyResponse)
async def get_policy(policy_id: str, db: AsyncSession = Depends(get_db)):
    """Get a single policy."""
    result = await db.execute(select(Policy).where(Policy.policy_id == policy_id))
    policy = result.scalar_one_or_none()
    if policy is None:
        raise HTTPException(status_code=404, detail=f"Policy {policy_id} not found")
    return _policy_to_response(policy)


def _policy_to_response(policy: Policy) -> PolicyResponse:
    return PolicyResponse(
        policy_id=policy.policy_id,
        worker_id=policy.worker_id,
        h3_zone=policy.h3_zone,
        tier=policy.tier,
        weekly_premium=float(policy.weekly_premium),
        coverage_percentage=float(policy.coverage_percentage),
        coverage_ceiling=float(policy.coverage_ceiling),
        start_date=policy.start_date,
        end_date=policy.end_date,
        status=policy.status,
        created_at=policy.created_at,
    )
