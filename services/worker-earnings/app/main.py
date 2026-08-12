"""
GigKavach — Worker & Earnings Service
Unified earnings dashboard, decision engine, boost recommendations.
"""

from fastapi import FastAPI
from contextlib import asynccontextmanager
from app.database import engine, create_tables
from app.routes import dashboard, earnings, decision


@asynccontextmanager
async def lifespan(app: FastAPI):
    await create_tables()
    yield
    await engine.dispose()


app = FastAPI(
    title="GigKavach — Worker & Earnings Service",
    description="Unified dashboard, decision engine, earnings boost",
    version="2.0.0",
    lifespan=lifespan,
)

app.include_router(dashboard.router, prefix="/workers", tags=["Workers"])
app.include_router(earnings.router, prefix="/earnings", tags=["Earnings"])
app.include_router(decision.router, prefix="/decision", tags=["Decision"])


@app.get("/health")
async def health():
    return {"service": "worker-earnings", "status": "healthy"}
