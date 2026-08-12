"""
GigKavach — Claims & Payouts: Event-Sourced Claim State Machine

Every claim transitions through:
    TriggerDetected → FNOLCreated → FraudAdjudicated → ReserveSet
        → PayoutInitiated → PayoutCompleted | PayoutFailed

Each transition appends an event to claim_events (the source of truth)
and updates claims.current_state (denormalized for query convenience).
"""

import uuid
from datetime import datetime
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import Claim, ClaimEvent


class InvalidStateTransition(Exception):
    """Raised when a claim transition is not allowed from the current state."""
    def __init__(self, claim_id: str, current_state: str, target_state: str):
        self.claim_id = claim_id
        self.current_state = current_state
        self.target_state = target_state
        super().__init__(
            f"Claim {claim_id}: cannot transition from "
            f"'{current_state}' to '{target_state}'"
        )


# Valid transitions: current_state → set of allowed next states
VALID_TRANSITIONS = {
    "TriggerDetected": {"FNOLCreated"},
    "FNOLCreated": {"FraudAdjudicated"},
    "FraudAdjudicated": {"ReserveSet"},
    "ReserveSet": {"PayoutInitiated"},
    "PayoutInitiated": {"PayoutCompleted", "PayoutFailed"},
    "PayoutFailed": {"PayoutInitiated"},  # retry
    "PayoutCompleted": set(),  # terminal
}


async def create_claim(
    db: AsyncSession,
    worker_id: str,
    h3_zone: str,
    trigger_type: str,
    trigger_data: dict,
    policy_id: str = None,
) -> Claim:
    """
    Create a new claim in TriggerDetected state and emit the initial event.
    """
    claim_id = f"CLM-{uuid.uuid4().hex[:8].upper()}"

    claim = Claim(
        claim_id=claim_id,
        policy_id=policy_id,
        worker_id=worker_id,
        h3_zone=h3_zone,
        trigger_type=trigger_type,
        trigger_data=trigger_data,
        current_state="TriggerDetected",
    )
    db.add(claim)

    event = ClaimEvent(
        claim_id=claim_id,
        event_type="TriggerDetected",
        event_data={
            "trigger_type": trigger_type,
            "trigger_data": trigger_data,
            "h3_zone": h3_zone,
        },
    )
    db.add(event)
    await db.flush()

    return claim


async def transition_claim(
    db: AsyncSession,
    claim_id: str,
    target_state: str,
    event_data: dict = None,
) -> Claim:
    """
    Transition a claim to a new state.
    - Validates the transition is legal
    - Appends an event to claim_events
    - Updates claims.current_state
    """
    result = await db.execute(
        select(Claim).where(Claim.claim_id == claim_id).with_for_update()
    )
    claim = result.scalar_one_or_none()
    if claim is None:
        raise ValueError(f"Claim {claim_id} not found")

    current = claim.current_state
    allowed = VALID_TRANSITIONS.get(current, set())

    if target_state not in allowed:
        raise InvalidStateTransition(claim_id, current, target_state)

    # Append event
    event = ClaimEvent(
        claim_id=claim_id,
        event_type=target_state,
        event_data=event_data or {},
    )
    db.add(event)

    # Update denormalized state
    claim.current_state = target_state

    await db.flush()
    return claim


async def get_claim_with_events(
    db: AsyncSession, claim_id: str
) -> tuple:
    """
    Fetch a claim and all its events, ordered chronologically.
    Returns (claim, events) tuple.
    """
    claim_result = await db.execute(
        select(Claim).where(Claim.claim_id == claim_id)
    )
    claim = claim_result.scalar_one_or_none()
    if claim is None:
        return None, []

    events_result = await db.execute(
        select(ClaimEvent)
        .where(ClaimEvent.claim_id == claim_id)
        .order_by(ClaimEvent.created_at)
    )
    events = events_result.scalars().all()

    return claim, events


async def rebuild_state_from_events(
    db: AsyncSession, claim_id: str
) -> str:
    """
    Rebuild claim state purely from events (for audit/verification).
    Returns the final state after replaying all events.
    """
    events_result = await db.execute(
        select(ClaimEvent)
        .where(ClaimEvent.claim_id == claim_id)
        .order_by(ClaimEvent.created_at)
    )
    events = events_result.scalars().all()

    if not events:
        raise ValueError(f"No events found for claim {claim_id}")

    # The last event's type IS the current state
    return events[-1].event_type
