"""
GigKavach — Trust & Fraud: Device Verifier (10 pts)

Checks device and network integrity.
MOCK implementation — always returns full credit.
Real implementation would use Play Integrity API / DeviceCheck,
mock-location detection, and network fingerprinting.
"""

from app.services.confidence_scorer import DimensionResult


def verify_device(claim_data: dict) -> DimensionResult:
    """
    Verify device/network cleanliness (10 points max).

    MOCK: always awards 10 points.
    Real implementation would check:
    - Play Integrity API (Android) / DeviceCheck (iOS)
    - Mock location detection
    - VPN/proxy detection
    - Device fingerprint consistency
    """
    max_points = 10

    # Mock: always clean
    return DimensionResult(
        dimension="Device & Network Cleanliness",
        max_points=max_points,
        awarded_points=10,
        passed=True,
        detail="Device integrity verified (mock — real: Play Integrity API / DeviceCheck)",
    )
