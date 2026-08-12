"""
GigKavach — Claims & Payouts: Pydantic Schemas
Request/response models for all Claims & Payouts endpoints.
"""

from pydantic import BaseModel, Field
from typing import Optional, List
from decimal import Decimal
from datetime import datetime, date


# ── Claims ──

class ClaimCreateRequest(BaseModel):
    worker_id: str
    h3_zone: str
    trigger_type: str
    trigger_data: dict = Field(default_factory=dict)
    policy_id: Optional[str] = None


class ClaimEventResponse(BaseModel):
    event_type: str
    event_data: dict
    created_at: datetime


class ClaimResponse(BaseModel):
    claim_id: str
    worker_id: str
    h3_zone: str
    trigger_type: str
    trigger_data: dict
    current_state: str
    payout_amount: Optional[float] = None
    confidence_score: Optional[int] = None
    fraud_action: Optional[str] = None
    created_at: datetime
    events: List[ClaimEventResponse] = []


class ClaimListResponse(BaseModel):
    claims: List[ClaimResponse]
    total: int


# ── Payouts ──

class PayoutRequest(BaseModel):
    claim_id: str
    amount: float = Field(gt=0)
    idempotency_key: str = Field(min_length=1, max_length=255)


class PayoutResponse(BaseModel):
    claim_id: str
    amount: float
    idempotency_key: str
    status: str  # "completed", "duplicate", "failed"
    ledger_txn_ref: Optional[str] = None
    message: str


# ── Triggers ──

class TriggerEvaluateRequest(BaseModel):
    h3_zone: str
    city: str = "Chennai"


class TriggerResult(BaseModel):
    trigger_type: str
    label: str
    value: str
    threshold: str
    severity: str
    data: dict


class TriggerEvaluateResponse(BaseModel):
    h3_zone: str
    city: str
    triggers_checked: int
    active_triggers: List[TriggerResult]
    claims_created: List[str] = []


# ── Policies ──

class PolicyCreateRequest(BaseModel):
    worker_id: str
    h3_zone: str
    tier: str = "standard"
    weekly_premium: float
    coverage_percentage: float = 70.0
    coverage_ceiling: float
    start_date: date
    end_date: date


class PolicyResponse(BaseModel):
    policy_id: str
    worker_id: str
    h3_zone: str
    tier: str
    weekly_premium: float
    coverage_percentage: float
    coverage_ceiling: float
    start_date: date
    end_date: date
    status: str
    created_at: datetime


class PolicyListResponse(BaseModel):
    policies: List[PolicyResponse]
    total: int


# ── Ledger ──

class LedgerBalanceResponse(BaseModel):
    account_id: str
    balance: float
    total_credits: float
    total_debits: float
    entry_count: int
