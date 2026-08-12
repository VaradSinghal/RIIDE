"""
GigKavach — Trust & Fraud: Adjudication Route

Single endpoint called by Claims & Payouts service.
Never called by clients directly.
"""

from fastapi import APIRouter, Depends
from pydantic import BaseModel
from typing import Optional
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models import FraudSignal
from app.services.confidence_scorer import score_claim

router = APIRouter()


class AdjudicateRequest(BaseModel):
    claim_id: str
    worker_id: str
    trigger_type: str = "unknown"
    trigger_data: dict = {}
    location: dict = {}
    last_location: dict = {}
    timestamps: dict = {}
    recent_deliveries: Optional[int] = None
    time_diff_seconds: int = 300


class AdjudicateResponse(BaseModel):
    claim_id: str
    confidence_score: int
    action: str  # auto_approve, soft_review, reject
    breakdown: list
    explanation: str


from app.services.ai_fraud_agent import ai_fraud_agent

@router.post("/adjudicate")
async def adjudicate_claim(req: AdjudicateRequest, db: AsyncSession = Depends(get_db)):
    """
    Score a claim across all 5 trust dimensions.
    """
    claim_data = {
        "claim_id": req.claim_id,
        "worker_id": req.worker_id,
        "trigger_type": req.trigger_type,
        "trigger_data": req.trigger_data,
        "location": req.location,
        "last_location": req.last_location,
        "trigger_timestamp": req.timestamps.get("trigger"),
        "inactivity_onset": req.timestamps.get("inactivity_onset"),
        "recent_deliveries": req.recent_deliveries,
        "time_diff_seconds": req.time_diff_seconds,
    }

    result = score_claim(claim_data)
    
    # Run AI Fraud Detection
    telemetry = {
        "speed_kmh": 0, # Should be calculated, but use default/dummy for demo if absent
        "time_diff_sec": req.time_diff_seconds,
        "device_integrity": 0.95,
        "vpn_active": 0,
        "historical_claims": 1
    }
    ai_fraud_res = ai_fraud_agent.predict_fraud(telemetry)
    
    # Combine logic
    confidence = result.confidence_score
    if ai_fraud_res["is_anomaly"]:
        confidence -= 20
        result.action = "reject"
        result.explanation += " | AI Agent flagged anomalous telemetry."
        
    confidence = max(0, min(100, confidence))

    # Persist for audit trail
    signal = FraudSignal(
        claim_id=req.claim_id,
        worker_id=req.worker_id,
        confidence_score=confidence,
        action=result.action,
        breakdown=result.breakdown,
        explanation=result.explanation,
    )
    db.add(signal)
    await db.commit()

    return {
        "claim_id": req.claim_id,
        "confidence_score": confidence,
        "action": result.action,
        "breakdown": result.breakdown,
        "explanation": result.explanation,
        "ai_fraud_analysis": ai_fraud_res
    }
