from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
import httpx
import asyncio
import os
import logging

logger = logging.getLogger(__name__)

router = APIRouter()

RISK_PRICING_URL = os.getenv("RISK_PRICING_URL", "http://risk-pricing:8002")
CLAIMS_PAYOUTS_URL = os.getenv("CLAIMS_PAYOUTS_URL", "http://claims-payouts:8003")
TRUST_FRAUD_URL = os.getenv("TRUST_FRAUD_URL", "http://trust-fraud:8004")

class DemoClaimRequest(BaseModel):
    worker_id: str = "demo-worker"
    h3_zone: str = "872a10d83ffffff"
    city: str = "Chennai"
    claim_amount: float = 1500.0
    past_claims: int = 1
    # Fraud telemtry simulation
    speed_kmh: float = 30.0
    time_diff_sec: int = 300
    device_integrity: float = 1.0
    vpn_active: int = 0

@router.post("/orchestrate-claim")
async def orchestrate_claim(req: DemoClaimRequest):
    """
    Agent Orchestration Endpoint.
    Coordinates Trust-Fraud AI, Risk-Pricing AI, and Claims AI for a single decision.
    """
    async with httpx.AsyncClient(timeout=10.0) as client:
        # Step 1: Trust-Fraud AI Evaluation
        # We simulate the AI Fraud Agent inference directly or via an endpoint.
        # Since we haven't exposed a pure inference route, we can just call it via adjudicate or we built one? 
        # Wait, I didn't build a raw inference route on trust-fraud. 
        # For demo purposes, we will just simulate calling the models if they are on separate services, 
        # or we can hit the actual endpoints if we exposed them.
        pass

    # Actually, let's just make direct calls to the services since we have `/risk/weather`, `/adjudicate`, etc.
    # To truly orchestrate, let's fetch weather from Risk, pass it to Adjudicator.
    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            # 1. Fetch Weather (Risk AI)
            weather_res = await client.get(f"{RISK_PRICING_URL}/risk/weather/{req.h3_zone}?city={req.city}")
            weather_data = weather_res.json()
            severity_str = "low"
            if weather_data["weather"]["rainfall_6hr_mm"] > 40:
                severity_str = "high"
            elif weather_data["weather"]["rainfall_6hr_mm"] > 10:
                severity_str = "medium"
                
            # 2. Score Fraud (Trust AI)
            # The Trust service adjudicate route requires a claim_id, so we make a dummy claim.
            # Instead of making a full claim, let's just build the AI trace.
            
            fraud_payload = {
                "claim_id": "demo-claim",
                "worker_id": req.worker_id,
                "trigger_type": "heavy_rainfall",
                "trigger_data": weather_data,
                "time_diff_seconds": req.time_diff_sec
            }
            fraud_res = await client.post(f"{TRUST_FRAUD_URL}/adjudicate", json=fraud_payload)
            fraud_data = fraud_res.json()
            
            # The response has "ai_fraud_analysis" from our previous step
            ai_fraud = fraud_data.get("ai_fraud_analysis", {})
            trust_score = fraud_data.get("confidence_score", 100)
            
            # 3. Adjudicate (Claims AI)
            adj_payload = {
                "trust_score": trust_score,
                "severity_str": severity_str,
                "claim_amount": req.claim_amount,
                "past_claims": req.past_claims
            }
            adj_res = await client.post(f"{CLAIMS_PAYOUTS_URL}/claims/ai-adjudicate", json=adj_payload)
            adj_data = adj_res.json()
            
            return {
                "status": "success",
                "agent_trace": {
                    "step_1_fraud_detection": {
                        "agent": "IsolationForest Anomaly Detector",
                        "analysis": ai_fraud,
                        "trust_score": trust_score
                    },
                    "step_2_risk_assessment": {
                        "agent": "Weather & Zone Oracle",
                        "severity_determined": severity_str,
                        "raw_data": weather_data["weather"]
                    },
                    "step_3_adjudication": {
                        "agent": "GradientBoosting Adjudicator",
                        "decision": adj_data
                    }
                },
                "final_decision": adj_data.get("ai_action", "manual_review")
            }
    except Exception as e:
        logger.error(f"Orchestration error: {e}")
        raise HTTPException(status_code=500, detail=str(e))
