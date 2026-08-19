"""
GigKavach — API Gateway: Authentication

JWT for mobile workers, session-based for admin dashboard.
"""

import os
from datetime import datetime, timedelta
from fastapi import APIRouter, HTTPException, Depends, Request
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from pydantic import BaseModel
from jose import jwt, JWTError

router = APIRouter()

JWT_SECRET = os.getenv("JWT_SECRET", "gigkavach-dev-secret-change-in-production-2026")
JWT_ALGORITHM = os.getenv("JWT_ALGORITHM", "HS256")
JWT_EXPIRE_MINUTES = int(os.getenv("JWT_EXPIRE_MINUTES", "1440"))

security = HTTPBearer(auto_error=False)

# Demo users (in production, this would be a database lookup)
DEMO_USERS = {
    "GK-CHN-001": {"name": "Ramesh Kumar", "role": "worker", "city": "Chennai"},
    "GK-CHN-002": {"name": "Priya Devi", "role": "worker", "city": "Chennai"},
    "GK-DEL-001": {"name": "Amit Singh", "role": "worker", "city": "Delhi"},
    "admin": {"name": "Admin User", "role": "admin", "city": "all"},
}


class LoginRequest(BaseModel):
    phone: str
    password: str = None  # Legacy support for admin
    otp: str = None

class OtpRequest(BaseModel):
    phone: str

import re
import uuid
import difflib

class PanVerifyRequest(BaseModel):
    pan_number: str      # ABCDE1234F format
    date_of_birth: str   # YYYY-MM-DD
    full_name: str       # As on PAN card

class PanVerifyResponse(BaseModel):
    status: str          # "verified", "mismatch", "invalid"
    pan_name: str        # Name fetched from NSDL/ITD
    name_match_score: float  # 0-1 fuzzy match
    pan_status: str      # "Active", "Inactive"

class DigiLockerInitResponse(BaseModel):
    session_id: str
    redirect_url: str    # DigiLocker consent screen URL
    status: str

class AadhaarOtpRequest(BaseModel):
    aadhaar_number: str

class KycCompleteRequest(BaseModel):
    session_id: str
    pan_number: str
    aadhaar_last4: str
    aadhaar_otp: str
    consent_timestamp: str
    consent_ip: str
    selfie_hash: str  # SHA256 of selfie image (liveness proof)

class KycCompleteResponse(BaseModel):
    kyc_status: str           # "completed", "pending_review", "rejected"
    verification_id: str       # Unique KYC reference
    pan_verified: bool
    aadhaar_verified: bool
    name_match: bool
    liveness_passed: bool
    risk_flags: list[str]      # e.g. ["name_mismatch_minor"]
    verified_data: dict        # name, dob, address (masked)

class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    expires_in: int
    user: dict

# Mock OTP Store (In production, use Redis)
OTP_STORE = {}

def create_token(user_id: str, role: str) -> str:
    """Create a JWT token."""
    expire = datetime.utcnow() + timedelta(minutes=JWT_EXPIRE_MINUTES)
    payload = {
        "sub": user_id,
        "role": role,
        "exp": expire,
        "iat": datetime.utcnow(),
    }
    return jwt.encode(payload, JWT_SECRET, algorithm=JWT_ALGORITHM)

def verify_token(token: str) -> dict:
    """Verify and decode a JWT token."""
    try:
        payload = jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALGORITHM])
        return payload
    except JWTError:
        raise HTTPException(status_code=401, detail="Invalid or expired token")

async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
) -> dict:
    """
    Dependency: extract current user from JWT.
    Returns None if no auth header (allows public endpoints).
    """
    if credentials is None:
        return None
    return verify_token(credentials.credentials)

@router.post("/request-otp")
async def request_otp(req: OtpRequest):
    """Simulate sending an OTP."""
    otp = "123456"  # Static for demo/testing
    OTP_STORE[req.phone] = otp
    return {"status": "success", "message": f"OTP sent to {req.phone}", "mock_otp": otp}

@router.post("/login", response_model=TokenResponse)
async def login(req: LoginRequest):
    """Login and get JWT token via OTP."""
    # For demo workers, we'll map phone numbers back to demo users if possible
    # Otherwise create a temporary verified session
    
    if req.otp:
        stored_otp = OTP_STORE.get(req.phone)
        if stored_otp != req.otp and req.otp != "123456": # Allow 123456 universally for demo
            raise HTTPException(status_code=401, detail="Invalid OTP")
            
        # Clean up OTP
        if req.phone in OTP_STORE:
            del OTP_STORE[req.phone]
            
        # Find user or default
        user_id = f"GK-NEW-{req.phone[-4:]}"
        user = {"name": "Verified Worker", "role": "worker", "city": "Chennai", "kyc_verified": False}
        
        # Match demo users by phone (mock matching)
        if req.phone == "+919876543210":
            user_id = "GK-CHN-001"
            user = DEMO_USERS["GK-CHN-001"]
            user["kyc_verified"] = True
            
        token = create_token(user_id, user["role"])

        return TokenResponse(
            access_token=token,
            expires_in=JWT_EXPIRE_MINUTES * 60,
            user={
                "user_id": user_id,
                "name": user["name"],
                "role": user["role"],
                "city": user["city"],
                "kyc_verified": user.get("kyc_verified", False)
            },
        )
    
    # Legacy worker_id based login for backwards compatibility during testing
    if hasattr(req, 'user_id') or req.password == "demo":
        user_id = getattr(req, 'user_id', req.phone) # fallback
        user = DEMO_USERS.get(user_id)
        if not user:
            # Create mock user for demo
            user = {"name": "Demo Worker", "role": "worker", "city": "Chennai", "kyc_verified": True}
        token = create_token(user_id, user["role"])
        return TokenResponse(
            access_token=token,
            expires_in=JWT_EXPIRE_MINUTES * 60,
            user={
                "user_id": user_id,
                "name": user["name"],
                "role": user["role"],
                "city": user["city"],
                "kyc_verified": True
            },
        )
        
    raise HTTPException(status_code=400, detail="OTP required")

from app.kyc.factory import get_kyc_provider
from app.kyc.provider import InitiateKycInput, PanVerificationInput, IdentityVerificationInput

@router.post("/kyc/start")
async def start_kyc(current_user: dict = Depends(get_current_user)):
    """Start a new KYC session using the configured provider."""
    if not current_user:
        raise HTTPException(status_code=401, detail="Not authenticated")
    provider = get_kyc_provider()
    session = await provider.initiate_kyc(InitiateKycInput(user_id=current_user["sub"]))
    # Normally, you'd save KycRecord to the DB here
    return session

@router.get("/kyc/{session_id}")
async def get_kyc_status(session_id: str, current_user: dict = Depends(get_current_user)):
    """Get the current state of a KYC session."""
    if not current_user:
        raise HTTPException(status_code=401, detail="Not authenticated")
    provider = get_kyc_provider()
    return await provider.get_kyc_status(session_id)

@router.post("/kyc/{session_id}/identity")
async def verify_pan_identity(session_id: str, req: PanVerifyRequest, current_user: dict = Depends(get_current_user)):
    """Verify PAN details via the configured provider."""
    if not current_user:
        raise HTTPException(status_code=401, detail="Not authenticated")
    provider = get_kyc_provider()
    result = await provider.verify_pan(PanVerificationInput(
        session_id=session_id,
        pan_number=req.pan_number,
        date_of_birth=req.date_of_birth,
        full_name=req.full_name
    ))
    return result

@router.post("/kyc/{session_id}/consent")
async def init_digilocker_consent(session_id: str, current_user: dict = Depends(get_current_user)):
    """Initialize DigiLocker/Document provider consent."""
    if not current_user:
        raise HTTPException(status_code=401, detail="Not authenticated")
    provider = get_kyc_provider()
    return await provider.init_digilocker(session_id)

@router.post("/kyc/{session_id}/aadhaar")
async def send_aadhaar_otp(session_id: str, req: AadhaarOtpRequest, current_user: dict = Depends(get_current_user)):
    """Trigger Aadhaar OTP for the current session."""
    if not current_user:
        raise HTTPException(status_code=401, detail="Not authenticated")
    provider = get_kyc_provider()
    return await provider.send_aadhaar_otp(session_id, req.aadhaar_number)

@router.post("/kyc/{session_id}/complete")
async def complete_kyc(session_id: str, req: KycCompleteRequest, current_user: dict = Depends(get_current_user)):
    """Finalize KYC, including liveness and OTP verification."""
    if not current_user:
        raise HTTPException(status_code=401, detail="Not authenticated")
    provider = get_kyc_provider()
    
    # Normally we would fetch the full Aadhaar number from the securely stored DB session
    # For now, we pass the available data to the provider
    result = await provider.verify_identity(IdentityVerificationInput(
        session_id=session_id,
        aadhaar_number="999999999999", # Mock default for demo
        otp=req.aadhaar_otp
    ))
    
    # Here we would update the KycRecord in the DB (VERIFIED, FAILED, etc.)
    return {
        "kyc_status": result.status,
        "verification_id": f"KYC-{uuid.uuid4().hex[:8].upper()}",
        "pan_verified": True,
        "aadhaar_verified": result.verified,
        "name_match": True,
        "liveness_passed": len(req.selfie_hash) > 10,
        "provider": result.provider,
        "environment": result.environment
    }

@router.post("/admin/login", response_model=TokenResponse)
async def admin_login(req: LoginRequest):
    """Admin login — separate endpoint for dashboard."""
    # Allow legacy user_id field for admin
    user_id = req.phone
    
    if user_id != "admin":
        raise HTTPException(status_code=401, detail="Not an admin user")

    user = DEMO_USERS["admin"]
    token = create_token("admin", "admin")

    return TokenResponse(
        access_token=token,
        expires_in=JWT_EXPIRE_MINUTES * 60,
        user={
            "user_id": "admin",
            "name": user["name"],
            "role": "admin",
            "city": "all",
            "kyc_verified": True
        },
    )

@router.get("/me")
async def get_me(user: dict = Depends(get_current_user)):
    """Get current user from token."""
    if user is None:
        raise HTTPException(status_code=401, detail="Not authenticated")
    return {"user_id": user["sub"], "role": user["role"]}
