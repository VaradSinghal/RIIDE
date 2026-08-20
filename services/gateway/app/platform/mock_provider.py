import uuid
from datetime import datetime, timedelta
from typing import Dict, Any, List

from app.platform.provider import (
    PlatformProvider, 
    PlatformLinkSession, 
    WorkHistory, 
    VerificationResult
)

class MockPlatformProvider(PlatformProvider):
    
    # Store temporary session state
    _sessions: Dict[str, PlatformLinkSession] = {}

    async def initiate_link(self, user_id: str, platform_name: str) -> PlatformLinkSession:
        session = PlatformLinkSession(
            session_id=str(uuid.uuid4()),
            user_id=user_id,
            platform_name=platform_name.lower(),
            status="PENDING",
            created_at=datetime.utcnow()
        )
        self._sessions[session.session_id] = session
        return session

    async def verify_login(self, session_id: str, phone: str, otp: str) -> bool:
        if session_id not in self._sessions:
            return False
            
        # Mock logic: any phone and OTP "123456" succeeds
        if otp == "123456":
            self._sessions[session_id].status = "VERIFIED"
            return True
            
        return False

    async def fetch_work_history(self, session_id: str) -> VerificationResult:
        if session_id not in self._sessions:
            raise ValueError("Invalid session")
            
        session = self._sessions[session_id]
        if session.status != "VERIFIED":
            raise ValueError("Session not verified")
            
        platform = session.platform_name
        
        # Mock responses based on platform
        history = []
        today = datetime.utcnow().date()
        
        if platform == "zomato":
            # High hours, stable income
            avg_hours = 12.5
            avg_inc = 950.0
            for i in range(14):
                dt = today - timedelta(days=i)
                history.append(WorkHistory(
                    date=dt.isoformat(),
                    hours_worked=12.5,
                    orders_completed=25,
                    gross_earnings=950.0
                ))
        elif platform == "swiggy":
            # Normal hours, lower income
            avg_hours = 8.0
            avg_inc = 600.0
            for i in range(14):
                dt = today - timedelta(days=i)
                history.append(WorkHistory(
                    date=dt.isoformat(),
                    hours_worked=8.0,
                    orders_completed=15,
                    gross_earnings=600.0
                ))
        else: # blinkit or others
            # Very high hours (fatigue risk!)
            avg_hours = 15.0
            avg_inc = 1200.0
            for i in range(14):
                dt = today - timedelta(days=i)
                history.append(WorkHistory(
                    date=dt.isoformat(),
                    hours_worked=15.0,
                    orders_completed=35,
                    gross_earnings=1200.0
                ))
                
        return VerificationResult(
            verified=True,
            platform=platform,
            avg_daily_hours=avg_hours,
            avg_daily_income=avg_inc,
            history=history
        )
