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

class KycRequest(BaseModel):
    document_type: str  # "aadhaar", "pan", "dl"
    document_number: str

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

@router.post("/kyc/verify")
async def verify_kyc(req: KycRequest, current_user: dict = Depends(get_current_user)):
    """Simulate DigiLocker KYC verification."""
    if not current_user:
        raise HTTPException(status_code=401, detail="Not authenticated")
        
    if len(req.document_number) < 5:
        raise HTTPException(status_code=400, detail="Invalid document number")
        
    # Simulate a successful DigiLocker fetch
    return {
        "status": "verified",
        "provider": "DigiLocker",
        "verified_data": {
            "name": "Verified User",
            "document_type": req.document_type,
            "dob": "1990-01-01",
            "address": "123 Main St, Tech City, 600001"
        }
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
