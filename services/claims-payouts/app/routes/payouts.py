"""
GigKavach — Claims & Payouts: Payouts Routes
Idempotent payout endpoint + ledger balance queries.
"""

from decimal import Decimal
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.schemas import PayoutRequest, PayoutResponse, LedgerBalanceResponse
from app.services.payout_processor import process_payout
from app.services.ledger import get_account_balance

router = APIRouter()


@router.post("/", response_model=PayoutResponse)
async def initiate_payout(req: PayoutRequest, db: AsyncSession = Depends(get_db)):
    """
    Initiate a payout for a claim.

    This endpoint is IDEMPOTENT: calling it twice with the same
    idempotency_key returns the same result and only moves money once.
    """
    result = await process_payout(
        db=db,
        claim_id=req.claim_id,
        amount=Decimal(str(req.amount)),
        idempotency_key=req.idempotency_key,
    )

    return PayoutResponse(
        claim_id=result.claim_id,
        amount=result.amount,
        idempotency_key=result.idempotency_key,
        status=result.status,
        ledger_txn_ref=result.ledger_txn_ref,
        message=result.message,
    )


@router.get("/balance/{account_id}", response_model=LedgerBalanceResponse)
async def get_balance(account_id: str, db: AsyncSession = Depends(get_db)):
    """
    Get account balance from the ledger.
    Balance = SUM(credit) - SUM(debit) — never a mutable column.
    """
    balance = await get_account_balance(db, account_id)
    return LedgerBalanceResponse(**balance)
