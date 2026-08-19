import uuid
import difflib
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

class MockKycProvider(KycProvider):
    
    async def initiate_kyc(self, input_data: InitiateKycInput) -> KycSession:
        return KycSession(
            session_id=str(uuid.uuid4()),
            user_id=input_data.user_id,
            provider="mock",
            status="PENDING",
            created_at=datetime.utcnow(),
            expires_at=datetime.utcnow() + timedelta(hours=1)
        )

    async def get_kyc_status(self, session_id: str) -> Dict[str, Any]:
        return {
            "session_id": session_id,
            "status": "PENDING",
            "provider": "mock",
            "environment": "development"
        }

    async def verify_pan(self, input_data: PanVerificationInput) -> VerificationResult:
        # Deterministic mock cases
        if input_data.pan_number.upper() == "ABCDE1234F":
            # Successful case
            return VerificationResult(
                verified=True,
                status="VALID",
                name_match_score=0.95,
                fetched_name=input_data.full_name.upper(),
                message="Mock PAN Verification Successful",
                provider="mock",
                environment="development"
            )
        elif input_data.pan_number.upper() == "XXXXX0000X":
            # Explicit failure case
            return VerificationResult(
                verified=False,
                status="INVALID",
                name_match_score=0.0,
                fetched_name="",
                message="Mock PAN Verification Failed",
                provider="mock",
                environment="development"
            )
        else:
            # Default fallback for testing
            mock_pan_name = input_data.full_name.upper()
            score = difflib.SequenceMatcher(None, input_data.full_name.upper(), mock_pan_name).ratio()
            verified = score > 0.85
            
            return VerificationResult(
                verified=verified,
                status="VALID" if verified else "INVALID",
                name_match_score=score,
                fetched_name=mock_pan_name,
                message="Mock Fallback Verification",
                provider="mock",
                environment="development"
            )

    async def init_digilocker(self, session_id: str) -> Dict[str, str]:
        return {
            "session_id": session_id,
            "redirect_url": f"https://mock-digilocker.local/consent?state={session_id}",
            "status": "initiated",
            "provider": "mock"
        }

    async def send_aadhaar_otp(self, session_id: str, aadhaar_number: str) -> Dict[str, str]:
        return {
            "status": "success",
            "message": "Mock OTP sent. Use 123456.",
            "provider": "mock"
        }

    async def verify_identity(self, input_data: IdentityVerificationInput) -> VerificationResult:
        # Deterministic test cases
        if input_data.aadhaar_number == "999999999999":
            verified = (input_data.otp == "123456")
            return VerificationResult(
                verified=verified,
                status="SUCCESS" if verified else "FAILED",
                message="Mock Identity Verified" if verified else "Mock OTP Failed",
                provider="mock",
                environment="development"
            )
        else:
            # Explicit failure
            return VerificationResult(
                verified=False,
                status="FAILED",
                message="Mock Identity Verification Failed (Use 999999999999 for success)",
                provider="mock",
                environment="development"
            )
