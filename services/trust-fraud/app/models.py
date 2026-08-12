"""
GigKavach — Trust & Fraud: Database Models
"""

import uuid
from datetime import datetime
from sqlalchemy import Column, String, Numeric, Integer, DateTime, JSON, Text
from sqlalchemy.dialects.postgresql import UUID

import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..'))
from shared.database import Base


class FraudSignal(Base):
    """Stored adjudication results for audit trail."""
    __tablename__ = "fraud_signals"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    claim_id = Column(String, nullable=False, index=True)
    worker_id = Column(String, nullable=False, index=True)
    confidence_score = Column(Integer, nullable=False)
    action = Column(String, nullable=False)
    breakdown = Column(JSON, nullable=False, default=dict)
    explanation = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), default=datetime.utcnow)


class TrustScore(Base):
    """Progressive trust scores per worker."""
    __tablename__ = "trust_scores"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    worker_id = Column(String, unique=True, nullable=False, index=True)
    score = Column(Numeric(5, 2), nullable=False, default=50)
    total_claims = Column(Integer, default=0)
    approved_claims = Column(Integer, default=0)
    rejected_claims = Column(Integer, default=0)
    updated_at = Column(DateTime(timezone=True), default=datetime.utcnow)
