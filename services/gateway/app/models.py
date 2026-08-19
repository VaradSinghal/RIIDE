"""
GigKavach — Gateway: Database Models
"""

import uuid
from datetime import datetime
from sqlalchemy import Column, String, Boolean, DateTime, Date, Numeric
from sqlalchemy.dialects.postgresql import UUID

import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..'))
from shared.database import Base


class KycRecord(Base):
    """Stores the state of identity verification (PAN, Aadhaar, Liveness)."""
    __tablename__ = "kyc_records"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    worker_id = Column(String, index=True) # Renamed to standard user identifier
    
    # Provider details
    provider = Column(String, default="mock") # e.g. mock, digilocker
    environment = Column(String, default="development")
    provider_session_id = Column(String, index=True, nullable=True)
    
    # State Machine
    kyc_status = Column(String, default="NOT_STARTED") # NOT_STARTED, PENDING, CONSENT_REQUIRED, IDENTITY_VERIFICATION, DOCUMENT_RETRIEVAL, VERIFIED, FAILED, EXPIRED, CANCELLED
    failure_reason = Column(String, nullable=True)
    
    # Identity Data (Masked or partial)
    pan_last4 = Column(String, nullable=True)
    aadhaar_last4 = Column(String, nullable=True)
    verified_name = Column(String, nullable=True)
    verified_dob = Column(Date, nullable=True)
    verification_result = Column(String, nullable=True) # JSON or string summary
    
    # Consent
    consent_given = Column(Boolean, default=False)
    consent_timestamp = Column(DateTime(timezone=True), nullable=True)
    consent_ip = Column(String, nullable=True)
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), default=datetime.utcnow)
    updated_at = Column(DateTime(timezone=True), default=datetime.utcnow, onupdate=datetime.utcnow)
    expires_at = Column(DateTime(timezone=True), nullable=True)

