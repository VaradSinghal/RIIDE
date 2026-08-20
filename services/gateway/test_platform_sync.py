import asyncio
import os
import httpx

os.environ["PLATFORM_PROVIDER"] = "mock"

async def test_integration():
    # 1. Gateway link
    async with httpx.AsyncClient() as client:
        # Mock a token, since we disabled auth internally for tests or we pass a mock user
        headers = {"Authorization": "Bearer mock_token"}
        
        # Link Zomato
        print("Linking Zomato...")
        resp = await client.post("http://localhost:8000/api/v1/auth/platform/link", 
            json={"platform_name": "zomato"}, headers=headers)
        session = resp.json()
        print(session)
        session_id = session.get("session_id")
        if not session_id:
            print("Failed to start session")
            return
            
        print("\nVerifying OTP...")
        resp = await client.post(f"http://localhost:8000/api/v1/auth/platform/{session_id}/verify",
            json={"phone": "9999999999", "otp": "123456"}, headers=headers)
        print(resp.json())
        
        print("\nSyncing data to worker-earnings...")
        resp = await client.post(f"http://localhost:8000/api/v1/auth/platform/{session_id}/sync", headers=headers)
        print(resp.json())
        
        # The premium API calculation
        print("\nCalculating premium...")
        resp = await client.post("http://localhost:8000/api/v1/demo/orchestrate/premium", 
            json={
                "worker_id": session.get("user_id", "test_user_1"),
                "h3_zone": "8861892539fffff", # Adyar
                "city": "Chennai",
                "avg_weekly_income": 4000.0,
                "verified_daily_hours": 12.5,  # Matches Zomato mock
                "verified_daily_income": 950.0 # Matches Zomato mock
            }, headers=headers)
        
        print(resp.json())
        
if __name__ == "__main__":
    asyncio.run(test_integration())
