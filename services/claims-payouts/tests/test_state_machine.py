"""
GigKavach — Claims & Payouts: State Machine Tests
"""

import pytest
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession

import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from shared.database import Base
from app.models import Claim, ClaimEvent
from app.services.claim_state_machine import (
    create_claim, transition_claim, get_claim_with_events,
    rebuild_state_from_events, InvalidStateTransition,
)

TEST_DB_URL = "sqlite+aiosqlite:///:memory:"


@pytest.fixture
async def db_session():
    engine = create_async_engine(TEST_DB_URL, echo=False)
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    session_factory = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    async with session_factory() as session:
        yield session
    await engine.dispose()


@pytest.mark.asyncio
async def test_full_claim_lifecycle(db_session):
    """Walk a claim through the full happy-path lifecycle."""
    db = db_session

    # Create → TriggerDetected
    claim = await create_claim(
        db=db,
        worker_id="GK-TEST-001",
        h3_zone="872a10000ffffff",
        trigger_type="heavy_rainfall",
        trigger_data={"rainfall_6hr_mm": 55},
    )
    assert claim.current_state == "TriggerDetected"

    # TriggerDetected → FNOLCreated
    await transition_claim(db, claim.claim_id, "FNOLCreated", {"auto_filed": True})
    assert claim.current_state == "FNOLCreated"

    # FNOLCreated → FraudAdjudicated
    await transition_claim(db, claim.claim_id, "FraudAdjudicated", {
        "confidence_score": 92,
        "action": "auto_approve",
    })
    assert claim.current_state == "FraudAdjudicated"

    # FraudAdjudicated → ReserveSet
    await transition_claim(db, claim.claim_id, "ReserveSet", {"amount": 350})
    assert claim.current_state == "ReserveSet"

    # ReserveSet → PayoutInitiated
    await transition_claim(db, claim.claim_id, "PayoutInitiated", {
        "gateway": "mock_razorpay",
    })
    assert claim.current_state == "PayoutInitiated"

    # PayoutInitiated → PayoutCompleted
    await transition_claim(db, claim.claim_id, "PayoutCompleted", {
        "transaction_id": "TXN-123",
    })
    assert claim.current_state == "PayoutCompleted"

    await db.commit()

    # Verify event log has all 6 events
    _, events = await get_claim_with_events(db, claim.claim_id)
    assert len(events) == 6
    event_types = [e.event_type for e in events]
    assert event_types == [
        "TriggerDetected", "FNOLCreated", "FraudAdjudicated",
        "ReserveSet", "PayoutInitiated", "PayoutCompleted",
    ]


@pytest.mark.asyncio
async def test_invalid_transition_raises(db_session):
    """Cannot skip states — e.g. TriggerDetected cannot jump to PayoutCompleted."""
    db = db_session

    claim = await create_claim(
        db=db,
        worker_id="GK-TEST-002",
        h3_zone="872a10000ffffff",
        trigger_type="severe_aqi",
        trigger_data={"aqi": 400},
    )

    with pytest.raises(InvalidStateTransition):
        await transition_claim(db, claim.claim_id, "PayoutCompleted", {})


@pytest.mark.asyncio
async def test_payout_failed_can_retry(db_session):
    """PayoutFailed → PayoutInitiated (retry) is a valid transition."""
    db = db_session

    claim = await create_claim(
        db=db, worker_id="GK-TEST-003", h3_zone="872a10000ffffff",
        trigger_type="flooding", trigger_data={},
    )

    # Walk to PayoutInitiated
    await transition_claim(db, claim.claim_id, "FNOLCreated")
    await transition_claim(db, claim.claim_id, "FraudAdjudicated")
    await transition_claim(db, claim.claim_id, "ReserveSet")
    await transition_claim(db, claim.claim_id, "PayoutInitiated")

    # Fail
    await transition_claim(db, claim.claim_id, "PayoutFailed", {"reason": "gateway timeout"})
    assert claim.current_state == "PayoutFailed"

    # Retry
    await transition_claim(db, claim.claim_id, "PayoutInitiated", {"retry": True})
    assert claim.current_state == "PayoutInitiated"

    # Complete
    await transition_claim(db, claim.claim_id, "PayoutCompleted", {"txn": "TXN-RETRY"})
    assert claim.current_state == "PayoutCompleted"

    await db.commit()


@pytest.mark.asyncio
async def test_rebuild_state_from_events(db_session):
    """State can be reconstructed purely from the event log."""
    db = db_session

    claim = await create_claim(
        db=db, worker_id="GK-TEST-004", h3_zone="872a10000ffffff",
        trigger_type="extreme_heat", trigger_data={"temp_c": 45},
    )
    await transition_claim(db, claim.claim_id, "FNOLCreated")
    await transition_claim(db, claim.claim_id, "FraudAdjudicated")
    await db.commit()

    rebuilt_state = await rebuild_state_from_events(db, claim.claim_id)
    assert rebuilt_state == "FraudAdjudicated"
    assert rebuilt_state == claim.current_state


@pytest.mark.asyncio
async def test_completed_is_terminal(db_session):
    """PayoutCompleted is a terminal state — no further transitions allowed."""
    db = db_session

    claim = await create_claim(
        db=db, worker_id="GK-TEST-005", h3_zone="872a10000ffffff",
        trigger_type="civic_disruption", trigger_data={},
    )
    await transition_claim(db, claim.claim_id, "FNOLCreated")
    await transition_claim(db, claim.claim_id, "FraudAdjudicated")
    await transition_claim(db, claim.claim_id, "ReserveSet")
    await transition_claim(db, claim.claim_id, "PayoutInitiated")
    await transition_claim(db, claim.claim_id, "PayoutCompleted")

    with pytest.raises(InvalidStateTransition):
        await transition_claim(db, claim.claim_id, "FNOLCreated")
