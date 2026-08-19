import os
import uuid
from datetime import datetime, timedelta
from typing import Dict, Any

from app.kyc.provider import (
    KycProvider, 
    InitiateKycInput, 
    KycSession, 
    PanVerificationInput, 
    IdentityVerificationInput, 
    VerificationResult
)

class DigiLockerKycProvider(KycProvider):
    
    def __init__(self):
        self.client_id = os.getenv("DIGILOCKER_CLIENT_ID")
        self.client_secret = os.getenv("DIGILOCKER_CLIENT_SECRET")
        self.redirect_uri = os.getenv("DIGILOCKER_REDIRECT_URI")
        self.base_url = os.getenv("DIGILOCKER_BASE_URL")
        
        # We don't crash here so that the app can start, but calls will fail if missing credentials.
    
    def _check_config(self):
        if not self.client_id or not self.client_secret:
            raise RuntimeError("DigiLocker credentials missing in environment.")
            
    async def initiate_kyc(self, input_data: InitiateKycInput) -> KycSession:
        return KycSession(
            session_id=str(uuid.uuid4()),
            user_id=input_data.user_id,
            provider="digilocker",
            status="PENDING",
            created_at=datetime.utcnow(),
            expires_at=datetime.utcnow() + timedelta(hours=1)
        )

    async def get_kyc_status(self, session_id: str) -> Dict[str, Any]:
        return {
            "session_id": session_id,
            "status": "PENDING",
            "provider": "digilocker",
            "environment": "production"
        }

    async def verify_pan(self, input_data: PanVerificationInput) -> VerificationResult:
        self._check_config()
        # TODO: Implement actual NSDL/DigiLocker PAN verification API call
        # For now, return a NotImplementedError or fail safely
        return VerificationResult(
            verified=False,
            status="FAILED",
            message="DigiLocker PAN Verification Not Implemented Yet",
            provider="digilocker",
            environment="production"
        )

    async def init_digilocker(self, session_id: str) -> Dict[str, str]:
        self._check_config()
        redirect_url = f"{self.base_url}/oauth2/1/authorize?response_type=code&client_id={self.client_id}&state={session_id}&redirect_uri={self.redirect_uri}"
        return {
            "session_id": session_id,
            "redirect_url": redirect_url,
            "status": "initiated",
            "provider": "digilocker"
        }

    async def send_aadhaar_otp(self, session_id: str, aadhaar_number: str) -> Dict[str, str]:
        self._check_config()
        # TODO: Implement actual UIDAI/DigiLocker OTP API Call
        return {
            "status": "failed",
            "message": "Not implemented",
            "provider": "digilocker"
        }

    async def verify_identity(self, input_data: IdentityVerificationInput) -> VerificationResult:
        self._check_config()
        # TODO: Implement actual DigiLocker document fetch and match
        return VerificationResult(
            verified=False,
            status="FAILED",
            message="DigiLocker Identity Verification Not Implemented Yet",
            provider="digilocker",
            environment="production"
        )
