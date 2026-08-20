import httpx
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from typing import Dict, Any

from app.auth import get_current_user
from app.platform.factory import get_platform_provider

router = APIRouter()

class PlatformLinkRequest(BaseModel):
    platform_name: str

class PlatformVerifyRequest(BaseModel):
    phone: str
    otp: str

@router.post("/link")
async def link_platform(req: PlatformLinkRequest, current_user: dict = Depends(get_current_user)):
    """Initiate a link to a gig platform."""
    if not current_user:
        raise HTTPException(status_code=401, detail="Not authenticated")
        
    provider = get_platform_provider()
    session = await provider.initiate_link(current_user["sub"], req.platform_name)
    return session

@router.post("/{session_id}/verify")
async def verify_platform_login(session_id: str, req: PlatformVerifyRequest, current_user: dict = Depends(get_current_user)):
    """Verify OTP for the platform login."""
    if not current_user:
        raise HTTPException(status_code=401, detail="Not authenticated")
        
    provider = get_platform_provider()
    success = await provider.verify_login(session_id, req.phone, req.otp)
    
    if not success:
        raise HTTPException(status_code=400, detail="Invalid OTP or Session")
        
    return {"status": "success", "message": "Platform linked successfully"}

@router.post("/{session_id}/sync")
async def sync_platform_data(session_id: str, current_user: dict = Depends(get_current_user)):
    """Fetch data from the platform and sync it to the worker-earnings service."""
    if not current_user:
        raise HTTPException(status_code=401, detail="Not authenticated")
        
    provider = get_platform_provider()
    
    try:
        result = await provider.fetch_work_history(session_id)
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))
        
    # Forward the synced data to the worker-earnings service
    # In a real app, this would use a service mesh or internal auth, and async client
    # We will assume worker-earnings is running on port 8002
    payload = {
        "worker_id": current_user["sub"],
        "platform": result.platform,
        "avg_daily_hours": result.avg_daily_hours,
        "avg_daily_income": result.avg_daily_income,
        "history": [h.dict() for h in result.history]
    }
    
    try:
        async with httpx.AsyncClient() as client:
            resp = await client.post("http://localhost:8002/platform/sync", json=payload, timeout=10.0)
            if resp.status_code != 200:
                print(f"Error syncing to worker-earnings: {resp.text}")
                # We'll just swallow it in dev if the service isn't up, or return error
                # raise HTTPException(status_code=500, detail="Failed to sync to upstream service")
    except Exception as e:
        print(f"Connection to worker-earnings failed: {e}")
    
    return result
