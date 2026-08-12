"""
GigKavach — Claims & Payouts: Double-Entry Ledger

Append-only ledger. Balances are ALWAYS computed as:
    SUM(credit) - SUM(debit) WHERE account_id = ?

NEVER a mutable balance column. The UNIQUE constraint on idempotency_key
prevents duplicate entries from being created.
"""

import uuid
from decimal import Decimal
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.exc import IntegrityError

from app.models import LedgerEntry


class DuplicateLedgerEntry(Exception):
    """Raised when an idempotency key has already been processed."""
    pass


async def record_double_entry(
    db: AsyncSession,
    debit_account: str,
    credit_account: str,
    amount: Decimal,
    txn_ref: str,
    idempotency_key: str,
    description: str = None,
) -> tuple:
    """
    Record a paired double-entry transaction.

    Creates exactly two rows:
      1. DEBIT on debit_account (money leaving)
      2. CREDIT on credit_account (money arriving)

    The idempotency_key UNIQUE constraint ensures this is safe to retry:
    if the key already exists, raises DuplicateLedgerEntry instead of
    creating a second pair.

    Returns (debit_entry, credit_entry) on success.
    """
    if amount <= 0:
        raise ValueError("Ledger amount must be positive")

    debit_key = f"{idempotency_key}__debit"
    credit_key = f"{idempotency_key}__credit"

    debit_entry = LedgerEntry(
        account_id=debit_account,
        debit=amount,
        credit=Decimal("0"),
        txn_ref=txn_ref,
        idempotency_key=debit_key,
        description=description or f"Debit {debit_account}: {txn_ref}",
    )

    credit_entry = LedgerEntry(
        account_id=credit_account,
        debit=Decimal("0"),
        credit=amount,
        txn_ref=txn_ref,
        idempotency_key=credit_key,
        description=description or f"Credit {credit_account}: {txn_ref}",
    )

    try:
        db.add(debit_entry)
        db.add(credit_entry)
        await db.flush()
    except IntegrityError:
        await db.rollback()
        raise DuplicateLedgerEntry(
            f"Idempotency key '{idempotency_key}' has already been processed"
        )

    return debit_entry, credit_entry


async def get_account_balance(db: AsyncSession, account_id: str) -> dict:
    """
    Compute account balance from ledger entries.
    Balance = SUM(credit) - SUM(debit)
    """
    result = await db.execute(
        select(
            func.coalesce(func.sum(LedgerEntry.credit), Decimal("0")).label("total_credits"),
            func.coalesce(func.sum(LedgerEntry.debit), Decimal("0")).label("total_debits"),
            func.count(LedgerEntry.entry_id).label("entry_count"),
        ).where(LedgerEntry.account_id == account_id)
    )
    row = result.one()

    total_credits = row.total_credits or Decimal("0")
    total_debits = row.total_debits or Decimal("0")
    balance = total_credits - total_debits

    return {
        "account_id": account_id,
        "balance": float(balance),
        "total_credits": float(total_credits),
        "total_debits": float(total_debits),
        "entry_count": row.entry_count,
    }


async def get_entries_by_txn_ref(db: AsyncSession, txn_ref: str) -> list:
    """Get all ledger entries for a given transaction reference."""
    result = await db.execute(
        select(LedgerEntry)
        .where(LedgerEntry.txn_ref == txn_ref)
        .order_by(LedgerEntry.created_at)
    )
    return result.scalars().all()


async def check_idempotency_key_exists(db: AsyncSession, idempotency_key: str) -> bool:
    """Check if an idempotency key has already been used."""
    debit_key = f"{idempotency_key}__debit"
    result = await db.execute(
        select(LedgerEntry.entry_id).where(LedgerEntry.idempotency_key == debit_key).limit(1)
    )
    return result.scalar_one_or_none() is not None
