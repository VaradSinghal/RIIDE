"""
GigKavach — Claims & Payouts: Database Models
Event-sourced claims, append-only ledger, policies.
"""

import uuid
from datetime import datetime, date
from decimal import Decimal

from sqlalchemy import (
    Column, String, Numeric, Integer, Boolean, DateTime, Date,
    Text, JSON, CheckConstraint, UniqueConstraint, ForeignKey, Index
)
from sqlalchemy.dialects.postgresql import UUID

import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..'))
from shared.database import Base


class Policy(Base):
    """Active insurance policies."""
    __tablename__ = "policies"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    policy_id = Column(String, unique=True, nullable=False, index=True)
    worker_id = Column(String, nullable=False, index=True)
    h3_zone = Column(String, nullable=False)
    tier = Column(String, nullable=False, default="standard")
    weekly_premium = Column(Numeric(10, 2), nullable=False)
    coverage_percentage = Column(Numeric(5, 2), nullable=False, default=70)
    coverage_ceiling = Column(Numeric(10, 2), nullable=False)
    start_date = Column(Date, nullable=False)
    end_date = Column(Date, nullable=False)
    status = Column(String, nullable=False, default="active")
    created_at = Column(DateTime(timezone=True), default=datetime.utcnow)


class Claim(Base):
    """
    Claim header — current_state is denormalized for query convenience,
    but claim_events is the source of truth.
    """
    __tablename__ = "claims"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    claim_id = Column(String, unique=True, nullable=False, index=True)
    policy_id = Column(String, ForeignKey("policies.policy_id"), nullable=True)
    worker_id = Column(String, nullable=False, index=True)
    h3_zone = Column(String, nullable=False)
    trigger_type = Column(String, nullable=False)
    trigger_data = Column(JSON, nullable=False, default=dict)
    current_state = Column(String, nullable=False, default="TriggerDetected")
    payout_amount = Column(Numeric(10, 2), nullable=True)
    confidence_score = Column(Integer, nullable=True)
    fraud_action = Column(String, nullable=True)
    created_at = Column(DateTime(timezone=True), default=datetime.utcnow)


class ClaimEvent(Base):
    """
    Append-only event log — source of truth for claim state.
    Every state transition is recorded as an event.
    """
    __tablename__ = "claim_events"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    claim_id = Column(String, ForeignKey("claims.claim_id"), nullable=False, index=True)
    event_type = Column(String, nullable=False)
    event_data = Column(JSON, nullable=False, default=dict)
    created_at = Column(DateTime(timezone=True), default=datetime.utcnow)

    __table_args__ = (
        Index("ix_claim_events_claim_created", "claim_id", "created_at"),
    )


class LedgerEntry(Base):
    """
    Append-only double-entry ledger.
    Balance = SUM(credit) - SUM(debit) WHERE account_id = ?
    NEVER a mutable balance column.
    """
    __tablename__ = "ledger_entries"

    entry_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    account_id = Column(String, nullable=False, index=True)
    debit = Column(Numeric(12, 2), nullable=False, default=0)
    credit = Column(Numeric(12, 2), nullable=False, default=0)
    txn_ref = Column(String, nullable=False, index=True)
    idempotency_key = Column(String, unique=True, nullable=False)
    description = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), default=datetime.utcnow)

    __table_args__ = (
        CheckConstraint(
            "(debit > 0 AND credit = 0) OR (debit = 0 AND credit > 0)",
            name="chk_single_side"
        ),
        Index("ix_ledger_account_created", "account_id", "created_at"),
    )
