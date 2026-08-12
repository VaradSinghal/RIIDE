"""
GigKavach — Risk & Pricing Service
H3-based zone risk scoring, dynamic premium calculation, weather data providers.
"""

from fastapi import FastAPI
from contextlib import asynccontextmanager
from app.database import engine, create_tables
from app.routes import risk, premium


@asynccontextmanager
async def lifespan(app: FastAPI):
    await create_tables()
    yield
    await engine.dispose()


app = FastAPI(
    title="GigKavach — Risk & Pricing Service",
    description="H3 zone risk scoring, dynamic premium calculation",
    version="2.0.0",
    lifespan=lifespan,
)

app.include_router(risk.router, prefix="/risk", tags=["Risk"])
app.include_router(premium.router, prefix="/premium", tags=["Premium"])


@app.get("/health")
async def health():
    return {"service": "risk-pricing", "status": "healthy"}
