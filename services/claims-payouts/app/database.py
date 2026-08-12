"""
GigKavach — Claims & Payouts: Database session management
"""

import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..'))
from shared.database import create_async_db_engine, create_async_session_factory, Base

# Import models so they register with Base.metadata
from app.models import Policy, Claim, ClaimEvent, LedgerEntry  # noqa: F401

engine = create_async_db_engine(echo=False)
AsyncSessionLocal = create_async_session_factory(engine)


async def create_tables():
    """Create all tables for this service on startup."""
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)


async def get_db():
    """Dependency: yields an async DB session."""
    async with AsyncSessionLocal() as session:
        try:
            yield session
        finally:
            await session.close()
