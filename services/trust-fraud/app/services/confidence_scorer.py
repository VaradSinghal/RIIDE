"""
GigKavach — Trust & Fraud: Confidence Scorer

100-point scoring across 5 independently verified dimensions:
  - Environmental confirmation:  30 pts (env_verifier)
  - Location integrity:          25 pts (location_verifier)
  - Activity coherence:          20 pts (activity_verifier)
  - Timing correlation:          15 pts (timing_verifier)
  - Device/network cleanliness:  10 pts (device_verifier)

≥80 → auto_approve
50-79 → soft_review
<50 → reject (with human-readable explanation)
"""

from dataclasses import dataclass, field
from app.services.env_verifier import verify_environment
from app.services.location_verifier import verify_location
from app.services.activity_verifier import verify_activity
from app.services.timing_verifier import verify_timing
from app.services.device_verifier import verify_device


@dataclass
class DimensionResult:
    dimension: str
    max_points: int
    awarded_points: int
    passed: bool
    detail: str


@dataclass
class ConfidenceResult:
    confidence_score: int
    action: str
    breakdown: list  # List[DimensionResult]
    explanation: str


def score_claim(claim_data: dict) -> ConfidenceResult:
    """
    Score a claim across all 5 truth dimensions.
    Returns a ConfidenceResult with the total score, action, and breakdown.
    """
    dimensions = [
        verify_environment(claim_data),
        verify_location(claim_data),
        verify_activity(claim_data),
        verify_timing(claim_data),
        verify_device(claim_data),
    ]

    total_score = sum(d.awarded_points for d in dimensions)
    failed_dims = [d for d in dimensions if not d.passed]

    # Determine action
    if total_score >= 80:
        action = "auto_approve"
        explanation = (
            f"Claim auto-approved with confidence score {total_score}/100. "
            f"All verification dimensions passed threshold."
        )
    elif total_score >= 50:
        action = "soft_review"
        failed_names = ", ".join(d.dimension for d in failed_dims)
        explanation = (
            f"Claim flagged for soft review (score: {total_score}/100). "
            f"Dimensions needing review: {failed_names or 'marginal scores across dimensions'}."
        )
    else:
        action = "reject"
        failed_details = "; ".join(f"{d.dimension}: {d.detail}" for d in failed_dims)
        explanation = (
            f"Claim rejected (score: {total_score}/100). "
            f"Failed verifications: {failed_details}."
        )

    breakdown = [
        {
            "dimension": d.dimension,
            "max_points": d.max_points,
            "awarded_points": d.awarded_points,
            "passed": d.passed,
            "detail": d.detail,
        }
        for d in dimensions
    ]

    return ConfidenceResult(
        confidence_score=total_score,
        action=action,
        breakdown=breakdown,
        explanation=explanation,
    )
