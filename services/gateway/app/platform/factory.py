import os
from app.platform.provider import PlatformProvider
from app.platform.mock_provider import MockPlatformProvider

def get_platform_provider() -> PlatformProvider:
    provider_name = os.getenv("PLATFORM_PROVIDER", "mock").lower()
    
    if provider_name == "mock":
        return MockPlatformProvider()
    else:
        # In a real system, you might have TartanProvider, ArgyleProvider, etc.
        raise ValueError(f"Unknown PLATFORM_PROVIDER: {provider_name}")
