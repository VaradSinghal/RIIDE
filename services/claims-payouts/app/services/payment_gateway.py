"""
GigKavach — Claims & Payouts: Mock Payment Gateway

Logs the payout instead of hitting Razorpay/UPI.
Structured so a real RazorpayGateway can replace MockPaymentGateway
by changing one config variable.
"""

import uuid
import logging
from typing import Protocol
from dataclasses import dataclass
from decimal import Decimal

logger = logging.getLogger(__name__)


@dataclass
class PaymentResult:
    success: bool
    transaction_id: str
    amount: float
    message: str


class PaymentGateway(Protocol):
    """Interface for payment gateways — real implementations drop in here."""
    async def initiate_payout(
        self, worker_id: str, amount: Decimal, reference: str
    ) -> PaymentResult:
        ...


class MockPaymentGateway:
    """
    Mock Razorpay/UPI gateway — logs payouts instead of transferring money.
    Replace with RazorpayGateway for production.
    """

    async def initiate_payout(
        self, worker_id: str, amount: Decimal, reference: str
    ) -> PaymentResult:
        txn_id = f"TXN-{uuid.uuid4().hex[:10].upper()}"
        logger.info(
            f"[MOCK PAYOUT] ₹{amount} → worker:{worker_id} | "
            f"ref:{reference} | txn:{txn_id}"
        )
        return PaymentResult(
            success=True,
            transaction_id=txn_id,
            amount=float(amount),
            message=f"Mock payout of ₹{amount} to {worker_id} logged successfully",
        )


# Singleton — swap this for RazorpayGateway in production
payment_gateway: PaymentGateway = MockPaymentGateway()
