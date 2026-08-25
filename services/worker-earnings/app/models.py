"""
GigKavach — Worker & Earnings: Database Models
Workers, earnings log, decision scores.
"""

import uuid
from datetime import datetime, date
from sqlalchemy import Column, String, Numeric, Integer, DateTime, Date, Index, Boolean
from sqlalchemy.dialects.postgresql import UUID

import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..'))
from shared.database import Base


class Worker(Base):
    """Worker profiles — system of record."""
    __tablename__ = "workers"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    worker_id = Column(String, unique=True, nullable=False, index=True)
    name = Column(String, nullable=False)
    phone = Column(String, nullable=True)
    city = Column(String, nullable=False, index=True)
    h3_zone = Column(String, nullable=False)
    primary_platform = Column(String, nullable=False)
    secondary_platform = Column(String, nullable=True)
    vehicle_type = Column(String, nullable=False, default="bike")
    avg_daily_hours = Column(Numeric(4, 1), nullable=True)
    experience_weeks = Column(Integer, default=0)
    avg_daily_income = Column(Numeric(8, 2), nullable=True)
    avg_weekly_income = Column(Numeric(8, 2), nullable=True)
    is_income_verified = Column(Boolean, default=False)
    verified_platform = Column(String, nullable=True)
    created_at = Column(DateTime(timezone=True), default=datetime.utcnow)


class EarningsLog(Base):
    """Append-only earnings log — one row per shift/day per platform."""
    __tablename__ = "earnings_log"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    worker_id = Column(String, nullable=False, index=True)
    platform = Column(String, nullable=False)
    date = Column(Date, nullable=False)
    hours_worked = Column(Numeric(4, 1), nullable=False)
    orders_completed = Column(Integer, nullable=False)
    gross_earnings = Column(Numeric(8, 2), nullable=False)
    incentives = Column(Numeric(8, 2), default=0)
    tips = Column(Numeric(8, 2), default=0)
    created_at = Column(DateTime(timezone=True), default=datetime.utcnow)

    __table_args__ = (
        Index("ix_earnings_worker_date", "worker_id", "date"),
    )


class DecisionScore(Base):
    """Cached decision scores, recomputed periodically."""
    __tablename__ = "decision_scores"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    worker_id = Column(String, nullable=False, index=True)
    h3_zone = Column(String, nullable=False)
    demand_score = Column(Numeric(5, 2), nullable=False)
    weather_safety_score = Column(Numeric(5, 2), nullable=False)
    insurance_coverage_score = Column(Numeric(5, 2), nullable=False)
    historical_stability_score = Column(Numeric(5, 2), nullable=False)
    composite_score = Column(Numeric(5, 2), nullable=False)
    recommendation = Column(String, nullable=False)
    computed_at = Column(DateTime(timezone=True), default=datetime.utcnow)
