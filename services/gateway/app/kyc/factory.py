import os
from app.kyc.provider import KycProvider
from app.kyc.mock_provider import MockKycProvider
from app.kyc.digilocker_provider import DigiLockerKycProvider

def get_kyc_provider() -> KycProvider:
    provider_name = os.getenv("KYC_PROVIDER", "mock").lower()
    app_env = os.getenv("APP_ENV", "development").lower()
    
    if app_env == "production" and provider_name == "mock":
        # Prevent accidental mock KYC in production without explicit override
        allow_mock = os.getenv("ALLOW_MOCK_IN_PROD", "false").lower() == "true"
        if not allow_mock:
            raise RuntimeError("CRITICAL SECURITY ERROR: KYC_PROVIDER=mock is not allowed in APP_ENV=production. Override with ALLOW_MOCK_IN_PROD=true if intentional.")
            
    if provider_name == "digilocker":
        return DigiLockerKycProvider()
    elif provider_name == "mock":
        return MockKycProvider()
    else:
        raise ValueError(f"Unknown KYC_PROVIDER: {provider_name}")
