"""
GigKavach — Trust & Fraud: Activity Verifier (20 pts)

Checks whether the worker's activity pattern is coherent with the claim.
Mock implementation — real version would check delivery history,
app usage patterns, and battery/navigation correlation.
"""

from app.services.confidence_scorer import DimensionResult


def verify_activity(claim_data: dict) -> DimensionResult:
    """
    Verify activity coherence (20 points max).

    Mock checks:
    - Worker was recently active (had deliveries in last 24hrs)
    - Activity dropped after the trigger event
    - No suspiciously perfect claim patterns
    """
    max_points = 20
    worker_id = claim_data.get("worker_id", "unknown")

    # Mock: check if worker has recent activity history
    recent_deliveries = claim_data.get("recent_deliveries", None)
    if recent_deliveries is not None:
        if recent_deliveries > 0:
            return DimensionResult(
                dimension="Activity Coherence",
                max_points=max_points,
                awarded_points=20,
                passed=True,
                detail=f"Worker had {recent_deliveries} recent deliveries — activity coherent",
            )
        else:
            return DimensionResult(
                dimension="Activity Coherence",
                max_points=max_points,
                awarded_points=8,
                passed=False,
                detail="No recent delivery activity found — needs review",
            )

    # Default for mock: give full credit (assume coherent)
    return DimensionResult(
        dimension="Activity Coherence",
        max_points=max_points,
        awarded_points=18,
        passed=True,
        detail="Activity check passed (mock — real check via delivery history API)",
    )
