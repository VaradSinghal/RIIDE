import pytest
from fastapi.testclient import TestClient
from app.main import app
import os

# Set environment explicitly
os.environ["KYC_PROVIDER"] = "mock"
os.environ["APP_ENV"] = "development"

client = TestClient(app)

def test_kyc_flow():
    # Mock user token payload
    headers = {"Authorization": "Bearer mock_token"}
    
    # 1. Start KYC
    response = client.post("/api/v1/auth/kyc/start", headers=headers)
    assert response.status_code == 200
    data = response.json()
    session_id = data["session_id"]
    print(f"Session started: {session_id}")
    
    # 2. Verify PAN (Success case)
    response = client.post(
        f"/api/v1/auth/kyc/{session_id}/identity",
        headers=headers,
        json={"pan_number": "ABCDE1234F", "date_of_birth": "1990-01-01", "full_name": "Test User"}
    )
    assert response.status_code == 200
    assert response.json()["verified"] == True
    print("PAN Verified")
    
    # 3. DigiLocker Consent
    response = client.post(f"/api/v1/auth/kyc/{session_id}/consent", headers=headers)
    assert response.status_code == 200
    print("DigiLocker Consent initiated")
    
    # 4. Aadhaar OTP
    response = client.post(
        f"/api/v1/auth/kyc/{session_id}/aadhaar",
        headers=headers,
        json={"aadhaar_number": "999999999999"}
    )
    assert response.status_code == 200
    print("Aadhaar OTP Sent")
    
    # 5. Complete
    response = client.post(
        f"/api/v1/auth/kyc/{session_id}/complete",
        headers=headers,
        json={
            "session_id": session_id,
            "pan_number": "ABCDE1234F",
            "aadhaar_last4": "9999",
            "aadhaar_otp": "123456",
            "consent_timestamp": "2023-01-01T00:00:00Z",
            "consent_ip": "127.0.0.1",
            "selfie_hash": "dummyhashofliveness"
        }
    )
    assert response.status_code == 200
    assert response.json()["kyc_status"] == "SUCCESS"
    print("KYC Completed")

if __name__ == "__main__":
    # In order to bypass dependency, we'll patch `get_current_user` in main
    from app.auth import get_current_user
    app.dependency_overrides[get_current_user] = lambda: {"sub": "user_123", "role": "worker", "city": "chennai"}
    
    print("Running KYC Test...")
    try:
        test_kyc_flow()
        print("ALL KYC ENDPOINTS WORK!")
    except Exception as e:
        print(f"FAILED: {e}")
