"""
GigKavach — Claims & Payouts: Idempotent Payout Processor

Orchestrates the full payout flow:
1. Check idempotency (no-op if key already processed)
2. Call Trust & Fraud service for adjudication
3. Advance claim through state machine
4. Write double-entry ledger
5. Call payment gateway
6. Return result

The UNIQUE constraint on idempotency_key in ledger_entries guarantees
that calling this twice with the same key only moves money once.
"""

import uuid
import logging
from decimal import Decimal
from dataclasses import dataclass

import httpx
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.services.claim_state_machine import transition_claim, InvalidStateTransition
from app.services.ledger import (
    record_double_entry,
    check_idempotency_key_exists,
    DuplicateLedgerEntry,
    get_account_balance,
)
from app.services.payment_gateway import payment_gateway

logger = logging.getLogger(__name__)

CLAIMS_RESERVE_ACCOUNT = "claims_reserve"


@dataclass
class PayoutResult:
    claim_id: str
    amount: float
    idempotency_key: str
    status: str  # "completed", "duplicate", "failed"
    ledger_txn_ref: str | None
    message: str


async def process_payout(
    db: AsyncSession,
    claim_id: str,
    amount: Decimal,
    idempotency_key: str,
    worker_id: str = None,
) -> PayoutResult:
    """
    Idempotent payout processor.

    Safe to call multiple times with the same idempotency_key —
    only the first call moves money.
    """

    # ── Step 1: Check idempotency ──
    already_processed = await check_idempotency_key_exists(db, idempotency_key)
    if already_processed:
        logger.info(f"[IDEMPOTENT] Key '{idempotency_key}' already processed — no-op")
        return PayoutResult(
            claim_id=claim_id,
            amount=float(amount),
            idempotency_key=idempotency_key,
            status="duplicate",
            ledger_txn_ref=None,
            message="Payout already processed (idempotent no-op)",
        )

    # ── Step 2: Call Trust & Fraud for adjudication ──
    fraud_result = await _call_trust_fraud(claim_id, worker_id or "unknown")
    confidence_score = fraud_result.get("confidence_score", 0)
    fraud_action = fraud_result.get("action", "reject")

    # Transition: FNOLCreated → FraudAdjudicated
    try:
        await transition_claim(db, claim_id, "FraudAdjudicated", {
            "confidence_score": confidence_score,
            "action": fraud_action,
            "breakdown": fraud_result.get("breakdown", {}),
        })
    except InvalidStateTransition:
        pass  # May already be in this state from a retry

    # If fraud rejects, stop here
    if fraud_action == "reject":
        await db.commit()
        return PayoutResult(
            claim_id=claim_id,
            amount=float(amount),
            idempotency_key=idempotency_key,
            status="failed",
            ledger_txn_ref=None,
            message=f"Claim rejected by fraud adjudication (score: {confidence_score})",
        )

    # ── Step 3: Set reserve ──
    try:
        await transition_claim(db, claim_id, "ReserveSet", {
            "amount": float(amount),
            "reserve_account": CLAIMS_RESERVE_ACCOUNT,
        })
    except InvalidStateTransition:
        pass

    # ── Step 4: Write ledger entries ──
    txn_ref = f"PAYOUT-{uuid.uuid4().hex[:8].upper()}"
    worker_account = f"worker:{worker_id or 'unknown'}"

    try:
        await record_double_entry(
            db=db,
            debit_account=CLAIMS_RESERVE_ACCOUNT,
            credit_account=worker_account,
            amount=amount,
            txn_ref=txn_ref,
            idempotency_key=idempotency_key,
            description=f"Payout for claim {claim_id}",
        )
    except DuplicateLedgerEntry:
        await db.commit()
        return PayoutResult(
            claim_id=claim_id,
            amount=float(amount),
            idempotency_key=idempotency_key,
            status="duplicate",
            ledger_txn_ref=None,
            message="Payout already processed (idempotent no-op)",
        )

    # ── Step 5: Initiate payout via payment gateway ──
    try:
        await transition_claim(db, claim_id, "PayoutInitiated", {
            "txn_ref": txn_ref,
            "amount": float(amount),
            "gateway": "mock_razorpay",
        })
    except InvalidStateTransition:
        pass

    payment_result = await payment_gateway.initiate_payout(
        worker_id=worker_id or "unknown",
        amount=amount,
        reference=txn_ref,
    )

    # ── Step 6: Complete or fail ──
    if payment_result.success:
        try:
            claim = await transition_claim(db, claim_id, "PayoutCompleted", {
                "transaction_id": payment_result.transaction_id,
                "amount": float(amount),
            })
            # Update denormalized payout_amount on claim header
            claim.payout_amount = amount
            claim.confidence_score = confidence_score
            claim.fraud_action = fraud_action
        except InvalidStateTransition:
            pass

        await db.commit()
        return PayoutResult(
            claim_id=claim_id,
            amount=float(amount),
            idempotency_key=idempotency_key,
            status="completed",
            ledger_txn_ref=txn_ref,
            message=f"Payout of ₹{amount} completed (txn: {payment_result.transaction_id})",
        )
    else:
        try:
            await transition_claim(db, claim_id, "PayoutFailed", {
                "reason": payment_result.message,
            })
        except InvalidStateTransition:
            pass

        await db.commit()
        return PayoutResult(
            claim_id=claim_id,
            amount=float(amount),
            idempotency_key=idempotency_key,
            status="failed",
            ledger_txn_ref=txn_ref,
            message=f"Payout failed: {payment_result.message}",
        )


async def _call_trust_fraud(claim_id: str, worker_id: str) -> dict:
    """
    Call the Trust & Fraud service for claim adjudication.
    Falls back to auto-approve if the service is unavailable.
    """
    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.post(
                f"{settings.TRUST_FRAUD_URL}/adjudicate",
                json={
                    "claim_id": claim_id,
                    "worker_id": worker_id,
                    "trigger_type": "unknown",
                    "location": {"lat": 13.0, "lon": 80.2},
                    "timestamps": {},
                },
            )
            if response.status_code == 200:
                return response.json()
    except Exception as e:
        logger.warning(f"Trust & Fraud service unavailable: {e}, defaulting to auto-approve")

    # Fallback: auto-approve with default score
    return {
        "confidence_score": 85,
        "action": "auto_approve",
        "breakdown": {"note": "Trust service unavailable — default approval"},
    }
