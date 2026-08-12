"""
GigKavach — Risk & Pricing: Database Models
H3 zone risk scores and premium quotes.
"""

import uuid
from datetime import datetime
from sqlalchemy import Column, String, Numeric, Boolean, DateTime, Index
from sqlalchemy.dialects.postgresql import UUID

import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..'))
from shared.database import Base


class H3Zone(Base):
    """H3 hexagonal zone with risk score."""
    __tablename__ = "h3_zones"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    h3_index = Column(String, unique=True, nullable=False, index=True)
    city = Column(String, nullable=False, index=True)
    zone_name = Column(String, nullable=True)
    risk_score = Column(Numeric(5, 2), nullable=False, default=50)
    risk_label = Column(String, nullable=False, default="Moderate")
    weather_risk_factor = Column(Numeric(3, 2), default=0.3)
    flood_prone = Column(Boolean, default=False)
    updated_at = Column(DateTime(timezone=True), default=datetime.utcnow)


class PremiumQuote(Base):
    """Immutable premium calculation records."""
    __tablename__ = "premium_quotes"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    worker_id = Column(String, nullable=False, index=True)
    h3_zone = Column(String, nullable=False)
    base_premium = Column(Numeric(10, 2), nullable=False)
    zone_risk_adjustment = Column(Numeric(10, 2), nullable=False)
    weather_forecast_adjustment = Column(Numeric(10, 2), nullable=False)
    weekly_premium = Column(Numeric(10, 2), nullable=False)
    coverage_ceiling = Column(Numeric(8, 2), nullable=False)
    
    # Advanced Underwriting Parameters
    vehicle_type = Column(String, default="bike")
    experience_weeks = Column(Integer, default=0)
    worker_age = Column(Integer, default=25)
    historical_claim_rate = Column(Numeric(4, 2), default=0.0)
    
    valid_from = Column(DateTime(timezone=True), nullable=False)
    valid_until = Column(DateTime(timezone=True), nullable=False)
    created_at = Column(DateTime(timezone=True), default=datetime.utcnow)

    __table_args__ = (
        Index("ix_premium_quotes_worker_zone", "worker_id", "h3_zone"),
    )
