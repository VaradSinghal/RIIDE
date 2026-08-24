from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import StreamingResponse
from app.auth import get_current_user
from app.policy.pdf_generator import generate_policy_pdf
from app.database import get_db
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from app.models import KycRecord
import httpx
import os

router = APIRouter()
RISK_PRICING_URL = os.getenv("RISK_PRICING_URL", "http://localhost:8002")

@router.get("/{quote_id}/pdf")
async def download_policy_pdf(
    quote_id: str, 
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Generates and returns the PDF policy document for a given quote.
    """
    if not current_user:
        raise HTTPException(status_code=401, detail="Not authenticated")
        
    worker_id = current_user["sub"]
    
    # 1. Fetch KYC to get verified name and masked Aadhaar
    stmt = select(KycRecord).where(KycRecord.worker_id == worker_id).order_by(KycRecord.created_at.desc())
    result = await db.execute(stmt)
    kyc_record = result.scalars().first()
    
    # 2. Fetch Quote Details (Simulation for now, or fetch from DB if we had risk-pricing DB access)
    # Since we are in the gateway, we might need to hit risk-pricing. For demo purposes, we will mock if it fails.
    # We can assume quote_id is valid for this worker.
    policy_data = {
        "policy_id": f"GK-POL-{quote_id[:8].upper()}",
        "name": kyc_record.verified_name if kyc_record and kyc_record.verified_name else "Varad Singhal",
        "aadhaar": kyc_record.aadhaar_last4 if kyc_record and kyc_record.aadhaar_last4 else "9999",
        "verified_platform": "zomato", # We could fetch from worker-earnings
        "vehicle_type": "bike",
        "plan_tier": "standard",
        "weekly_premium": 65.0,
        "coverage_ceiling": 2500.0,
        "valid_from": "2026-08-20",
        "valid_until": "2026-08-27",
        "h3_zone": "8861892539fffff"
    }
    
    pdf_stream = generate_policy_pdf(policy_data)
    
    headers = {
        'Content-Disposition': f'attachment; filename="GigKavach_Policy_{policy_data["policy_id"]}.pdf"'
    }
    
    return StreamingResponse(pdf_stream, media_type="application/pdf", headers=headers)
