"""
GigKavach — Shared Database Utilities
SQLAlchemy async engine factory and declarative base, shared across all services.
"""

import os
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession
from sqlalchemy.orm import DeclarativeBase
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker


class Base(DeclarativeBase):
    """Declarative base for all service models."""
    pass


def get_database_url() -> str:
    """Build async database URL from environment variables."""
    host = os.getenv("POSTGRES_HOST", "localhost")
    port = os.getenv("POSTGRES_PORT", "5432")
    db = os.getenv("POSTGRES_DB", "gigkavach")
    user = os.getenv("POSTGRES_USER", "gigkavach")
    password = os.getenv("POSTGRES_PASSWORD", "gigkavach_dev_2026")
    return f"postgresql+asyncpg://{user}:{password}@{host}:{port}/{db}"


def get_sync_database_url() -> str:
    """Build sync database URL (for Alembic migrations, seed scripts, tests)."""
    host = os.getenv("POSTGRES_HOST", "localhost")
    port = os.getenv("POSTGRES_PORT", "5432")
    db = os.getenv("POSTGRES_DB", "gigkavach")
    user = os.getenv("POSTGRES_USER", "gigkavach")
    password = os.getenv("POSTGRES_PASSWORD", "gigkavach_dev_2026")
    return f"postgresql://{user}:{password}@{host}:{port}/{db}"


def create_async_db_engine(echo: bool = False):
    """Create an async SQLAlchemy engine."""
    return create_async_engine(get_database_url(), echo=echo, pool_size=10, max_overflow=20)


def create_async_session_factory(engine) -> async_sessionmaker[AsyncSession]:
    """Create an async session factory bound to the given engine."""
    return async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)


def create_sync_engine(echo: bool = False):
    """Create a sync SQLAlchemy engine (for seeds/migrations)."""
    return create_engine(get_sync_database_url(), echo=echo)


def create_sync_session_factory(engine) -> sessionmaker:
    """Create a sync session factory."""
    return sessionmaker(bind=engine)
