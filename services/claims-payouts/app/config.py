"""
GigKavach — Claims & Payouts: Configuration
"""

import os


class Settings:
    POSTGRES_HOST: str = os.getenv("POSTGRES_HOST", "localhost")
    POSTGRES_PORT: str = os.getenv("POSTGRES_PORT", "5432")
    POSTGRES_DB: str = os.getenv("POSTGRES_DB", "gigkavach")
    POSTGRES_USER: str = os.getenv("POSTGRES_USER", "gigkavach")
    POSTGRES_PASSWORD: str = os.getenv("POSTGRES_PASSWORD", "gigkavach_dev_2026")

    TRUST_FRAUD_URL: str = os.getenv("TRUST_FRAUD_URL", "http://trust-fraud:8004")
    RISK_PRICING_URL: str = os.getenv("RISK_PRICING_URL", "http://risk-pricing:8002")


settings = Settings()
