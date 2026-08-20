"""
GigKavach — API Gateway
Single entry point for all client traffic.
Handles auth (JWT for mobile, session for admin), routing, CORS, rate limiting.
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.proxy import router as proxy_router
from app.auth import router as auth_router
from app.orchestrator import router as orchestrator_router
from app.platform_routes import router as platform_router

app = FastAPI(
    title="GigKavach — API Gateway",
    description="Single entry point for all GigKavach services",
    version="2.0.0",
)

# Fail fast if KYC config is invalid (e.g. mock in production)
try:
    from app.kyc.factory import get_kyc_provider
    get_kyc_provider()
except RuntimeError as e:
    import logging
    logging.error(f"Startup failed: {str(e)}")
    import sys
    sys.exit(1)

# CORS for Flutter app and React admin dashboard
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:5173",
        "http://localhost:5174",
        "http://127.0.0.1:5173",
        "http://localhost:3000",
        "http://localhost:8080",
        "*",  # Dev only — restrict in production
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth_router, prefix="/api/v1/auth", tags=["Auth"])
app.include_router(platform_router, prefix="/api/v1/auth/platform", tags=["Platform Integration"])
app.include_router(orchestrator_router, prefix="/api/v1/demo", tags=["Demo Orchestrator"])
app.include_router(proxy_router, prefix="/api/v1", tags=["Proxy"])


@app.get("/health")
async def health():
    return {"service": "gateway", "status": "healthy"}
