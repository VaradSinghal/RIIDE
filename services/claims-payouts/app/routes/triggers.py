"""
GigKavach — Claims & Payouts: Trigger Evaluation Routes
"""

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.schemas import TriggerEvaluateRequest, TriggerEvaluateResponse
from app.services.parametric_engine import evaluate_all_triggers, get_trigger_status
from app.services.claim_state_machine import create_claim, transition_claim

router = APIRouter()


@router.post("/evaluate", response_model=TriggerEvaluateResponse)
async def evaluate_triggers(req: TriggerEvaluateRequest, db: AsyncSession = Depends(get_db)):
    """
    Evaluate all 5 parametric triggers for a zone.
    If any trigger fires, auto-create claims for impacted workers.
    """
    active = await evaluate_all_triggers(req.h3_zone, req.city)
    claims_created = []

    # For demo: create a claim for each active trigger
    for trigger in active:
        claim = await create_claim(
            db=db,
            worker_id="demo-worker",
            h3_zone=req.h3_zone,
            trigger_type=trigger["trigger_type"],
            trigger_data=trigger["data"],
        )
        await transition_claim(db, claim.claim_id, "FNOLCreated", {
            "auto_filed": True,
            "trigger": trigger["label"],
        })
        claims_created.append(claim.claim_id)

    if claims_created:
        await db.commit()

    return TriggerEvaluateResponse(
        h3_zone=req.h3_zone,
        city=req.city,
        triggers_checked=5,
        active_triggers=active,
        claims_created=claims_created,
    )


@router.get("/status")
async def trigger_status(h3_zone: str, city: str = "Chennai"):
    """Get current status of all 5 triggers for a zone."""
    status = await get_trigger_status(h3_zone, city)
    return {"h3_zone": h3_zone, "city": city, "triggers": status}
