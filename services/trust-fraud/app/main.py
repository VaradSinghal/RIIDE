"""
GigKavach — Trust & Fraud Service
Independent service for claim adjudication — called by Claims & Payouts, never by clients.
100-point confidence scoring across 5 dimensions.
"""

from fastapi import FastAPI
from contextlib import asynccontextmanager
from app.database import engine, create_tables
from app.routes import adjudicate


@asynccontextmanager
async def lifespan(app: FastAPI):
    await create_tables()
    yield
    await engine.dispose()


app = FastAPI(
    title="GigKavach — Trust & Fraud Service",
    description="Independent claim adjudication and confidence scoring",
    version="2.0.0",
    lifespan=lifespan,
)

app.include_router(adjudicate.router, tags=["Adjudication"])


@app.get("/health")
async def health():
    return {"service": "trust-fraud", "status": "healthy"}
