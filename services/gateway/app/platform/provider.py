from abc import ABC, abstractmethod
from typing import Dict, Any, List
from pydantic import BaseModel
from datetime import datetime

class PlatformLinkSession(BaseModel):
    session_id: str
    user_id: str
    platform_name: str
    status: str
    created_at: datetime

class WorkHistory(BaseModel):
    date: str
    hours_worked: float
    orders_completed: int
    gross_earnings: float

class VerificationResult(BaseModel):
    verified: bool
    platform: str
    avg_daily_hours: float
    avg_daily_income: float
    history: List[WorkHistory]

class PlatformProvider(ABC):
    @abstractmethod
    async def initiate_link(self, user_id: str, platform_name: str) -> PlatformLinkSession:
        pass

    @abstractmethod
    async def verify_login(self, session_id: str, phone: str, otp: str) -> bool:
        pass

    @abstractmethod
    async def fetch_work_history(self, session_id: str) -> VerificationResult:
        pass
