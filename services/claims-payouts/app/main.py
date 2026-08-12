"""
GigKavach — Claims & Payouts Service
Event-sourced claim state machine, double-entry ledger, idempotent payouts.
"""

from fastapi import FastAPI
from contextlib import asynccontextmanager
from app.database import engine, create_tables
from app.routes import claims, payouts, triggers, policies


@asynccontextmanager
async def lifespan(app: FastAPI):
    await create_tables()
    yield
    await engine.dispose()


app = FastAPI(
    title="GigKavach — Claims & Payouts Service",
    description="Event-sourced claims, double-entry ledger, idempotent payouts",
    version="2.0.0",
    lifespan=lifespan,
)

app.include_router(claims.router, prefix="/claims", tags=["Claims"])
app.include_router(payouts.router, prefix="/payouts", tags=["Payouts"])
app.include_router(triggers.router, prefix="/triggers", tags=["Triggers"])
app.include_router(policies.router, prefix="/policies", tags=["Policies"])


@app.get("/health")
async def health():
    return {"service": "claims-payouts", "status": "healthy"}
