from abc import ABC, abstractmethod
from typing import Dict, Any, Optional
from pydantic import BaseModel
from datetime import datetime

class InitiateKycInput(BaseModel):
    user_id: str

class KycSession(BaseModel):
    session_id: str
    user_id: str
    provider: str
    status: str
    created_at: datetime
    expires_at: datetime
    provider_session_id: Optional[str] = None
    redirect_url: Optional[str] = None

class PanVerificationInput(BaseModel):
    session_id: str
    pan_number: str
    date_of_birth: str
    full_name: str

class IdentityVerificationInput(BaseModel):
    session_id: str
    aadhaar_number: str
    otp: str

class VerificationResult(BaseModel):
    verified: bool
    status: str
    name_match_score: Optional[float] = None
    fetched_name: Optional[str] = None
    message: Optional[str] = None
    provider: str
    environment: str

class KycProvider(ABC):
    
    @abstractmethod
    async def initiate_kyc(self, input_data: InitiateKycInput) -> KycSession:
        pass

    @abstractmethod
    async def get_kyc_status(self, session_id: str) -> Dict[str, Any]:
        pass

    @abstractmethod
    async def verify_pan(self, input_data: PanVerificationInput) -> VerificationResult:
        pass

    @abstractmethod
    async def init_digilocker(self, session_id: str) -> Dict[str, str]:
        pass

    @abstractmethod
    async def send_aadhaar_otp(self, session_id: str, aadhaar_number: str) -> Dict[str, str]:
        pass

    @abstractmethod
    async def verify_identity(self, input_data: IdentityVerificationInput) -> VerificationResult:
        pass
