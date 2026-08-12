"""
GigKavach — Claims & Payouts: Claims Routes
"""

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models import Claim, ClaimEvent
from app.schemas import (
    ClaimCreateRequest, ClaimResponse, ClaimListResponse, ClaimEventResponse,
)
from app.services.claim_state_machine import (
    create_claim, transition_claim, get_claim_with_events, InvalidStateTransition,
)

router = APIRouter()


@router.post("/", response_model=ClaimResponse)
async def create_new_claim(req: ClaimCreateRequest, db: AsyncSession = Depends(get_db)):
    """Create a new claim in TriggerDetected state."""
    claim = await create_claim(
        db=db,
        worker_id=req.worker_id,
        h3_zone=req.h3_zone,
        trigger_type=req.trigger_type,
        trigger_data=req.trigger_data,
        policy_id=req.policy_id,
    )

    # Transition: TriggerDetected → FNOLCreated (auto-file)
    await transition_claim(db, claim.claim_id, "FNOLCreated", {
        "auto_filed": True,
        "source": "parametric_engine",
    })

    await db.commit()

    claim, events = await get_claim_with_events(db, claim.claim_id)
    return _claim_to_response(claim, events)


from app.services.ai_adjudicator import ai_adjudicator

class AIAdjudicateRequest(BaseModel):
    trust_score: float
    severity_str: str
    claim_amount: float
    past_claims: int

@router.post("/ai-adjudicate")
async def ai_adjudicate(req: AIAdjudicateRequest):
    """Run AI inference for claim adjudication."""
    res = ai_adjudicator.adjudicate_claim(
        trust_score=req.trust_score,
        severity_str=req.severity_str,
        claim_amount=req.claim_amount,
        past_claims=req.past_claims
    )
    return res

@router.get("/", response_model=ClaimListResponse)
async def list_claims(
    worker_id: str = None,
    state: str = None,
    limit: int = 50,
    offset: int = 0,
    db: AsyncSession = Depends(get_db),
):
    """List claims with optional filters."""
    query = select(Claim)
    count_query = select(func.count(Claim.id))

    if worker_id:
        query = query.where(Claim.worker_id == worker_id)
        count_query = count_query.where(Claim.worker_id == worker_id)
    if state:
        query = query.where(Claim.current_state == state)
        count_query = count_query.where(Claim.current_state == state)

    query = query.order_by(Claim.created_at.desc()).limit(limit).offset(offset)

    result = await db.execute(query)
    claims = result.scalars().all()

    total_result = await db.execute(count_query)
    total = total_result.scalar()

    return ClaimListResponse(
        claims=[_claim_to_response(c) for c in claims],
        total=total,
    )


@router.get("/{claim_id}", response_model=ClaimResponse)
async def get_claim(claim_id: str, db: AsyncSession = Depends(get_db)):
    """Get a single claim with its full event history."""
    claim, events = await get_claim_with_events(db, claim_id)
    if claim is None:
        raise HTTPException(status_code=404, detail=f"Claim {claim_id} not found")
    return _claim_to_response(claim, events)


@router.post("/{claim_id}/transition")
async def advance_claim(
    claim_id: str,
    target_state: str,
    event_data: dict = None,
    db: AsyncSession = Depends(get_db),
):
    """Manually advance a claim to a new state (admin use)."""
    try:
        claim = await transition_claim(db, claim_id, target_state, event_data or {})
        await db.commit()
        return {"claim_id": claim_id, "new_state": claim.current_state}
    except InvalidStateTransition as e:
        raise HTTPException(status_code=400, detail=str(e))
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))


def _claim_to_response(claim: Claim, events: list = None) -> ClaimResponse:
    """Convert a Claim model to a response schema."""
    event_responses = []
    if events:
        event_responses = [
            ClaimEventResponse(
                event_type=e.event_type,
                event_data=e.event_data or {},
                created_at=e.created_at,
            )
            for e in events
        ]

    return ClaimResponse(
        claim_id=claim.claim_id,
        worker_id=claim.worker_id,
        h3_zone=claim.h3_zone,
        trigger_type=claim.trigger_type,
        trigger_data=claim.trigger_data or {},
        current_state=claim.current_state,
        payout_amount=float(claim.payout_amount) if claim.payout_amount else None,
        confidence_score=claim.confidence_score,
        fraud_action=claim.fraud_action,
        created_at=claim.created_at,
        events=event_responses,
    )
