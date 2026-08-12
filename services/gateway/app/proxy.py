"""
GigKavach — API Gateway: Reverse Proxy

Routes requests to internal services by path prefix.
The mobile app and admin dashboard ONLY talk to the gateway.
"""

import os
import httpx
from fastapi import APIRouter, Request, Response, HTTPException

router = APIRouter()

# Internal service URLs
WORKER_EARNINGS_URL = os.getenv("WORKER_EARNINGS_URL", "http://worker-earnings:8001")
RISK_PRICING_URL = os.getenv("RISK_PRICING_URL", "http://risk-pricing:8002")
CLAIMS_PAYOUTS_URL = os.getenv("CLAIMS_PAYOUTS_URL", "http://claims-payouts:8003")
TRUST_FRAUD_URL = os.getenv("TRUST_FRAUD_URL", "http://trust-fraud:8004")

# Route mapping: path prefix → (service_url, strip_prefix)
ROUTE_MAP = {
    "/workers": (WORKER_EARNINGS_URL, "/workers"),
    "/earnings": (WORKER_EARNINGS_URL, "/earnings"),
    "/decision": (WORKER_EARNINGS_URL, "/decision"),
    "/risk": (RISK_PRICING_URL, "/risk"),
    "/premium": (RISK_PRICING_URL, "/premium"),
    "/claims": (CLAIMS_PAYOUTS_URL, "/claims"),
    "/payouts": (CLAIMS_PAYOUTS_URL, "/payouts"),
    "/triggers": (CLAIMS_PAYOUTS_URL, "/triggers"),
    "/policies": (CLAIMS_PAYOUTS_URL, "/policies"),
    "/fraud": (TRUST_FRAUD_URL, ""),
}


async def _proxy_request(
    service_url: str,
    path: str,
    request: Request,
) -> Response:
    """Forward a request to an internal service."""
    target_url = f"{service_url}{path}"

    # Forward query params
    if request.query_params:
        target_url += f"?{request.query_params}"

    # Read body
    body = await request.body()

    # Forward headers (strip host)
    headers = dict(request.headers)
    headers.pop("host", None)

    try:
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.request(
                method=request.method,
                url=target_url,
                content=body,
                headers=headers,
            )
            return Response(
                content=response.content,
                status_code=response.status_code,
                headers=dict(response.headers),
            )
    except httpx.ConnectError:
        raise HTTPException(
            status_code=502,
            detail=f"Service unavailable: {service_url}",
        )
    except httpx.TimeoutException:
        raise HTTPException(
            status_code=504,
            detail=f"Service timeout: {service_url}",
        )


@router.api_route(
    "/{path:path}",
    methods=["GET", "POST", "PUT", "DELETE", "PATCH"],
)
async def proxy(path: str, request: Request):
    """
    Catch-all proxy — routes requests to the correct internal service
    based on the first path segment.
    """
    # Find matching route
    for prefix, (service_url, service_prefix) in ROUTE_MAP.items():
        clean_prefix = prefix.lstrip("/")
        if path == clean_prefix or path.startswith(f"{clean_prefix}/"):
            # Build the service-internal path
            remaining = path[len(clean_prefix):]
            internal_path = f"{service_prefix}{remaining}"
            return await _proxy_request(service_url, internal_path, request)

    raise HTTPException(
        status_code=404,
        detail=f"No service route found for path: /{path}",
    )
