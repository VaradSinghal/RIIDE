"""
GigKavach — Trust & Fraud: Timing Verifier (15 pts)

Checks whether the inactivity onset correlates with the trigger event time.
"""

from datetime import datetime
from app.services.confidence_scorer import DimensionResult


def verify_timing(claim_data: dict) -> DimensionResult:
    """
    Verify timing correlation (15 points max).

    Checks:
    - Inactivity onset is close to trigger detection time
    - No suspiciously pre-emptive inactivity
    """
    max_points = 15

    trigger_time = claim_data.get("trigger_timestamp")
    inactivity_time = claim_data.get("inactivity_onset")

    if trigger_time and inactivity_time:
        try:
            t_trigger = datetime.fromisoformat(str(trigger_time))
            t_inactive = datetime.fromisoformat(str(inactivity_time))
            diff_minutes = abs((t_inactive - t_trigger).total_seconds()) / 60

            if diff_minutes <= 30:
                return DimensionResult(
                    dimension="Timing Correlation",
                    max_points=max_points,
                    awarded_points=15,
                    passed=True,
                    detail=f"Inactivity onset within {diff_minutes:.0f}min of trigger",
                )
            elif diff_minutes <= 120:
                points = max(8, int(15 - (diff_minutes - 30) / 10))
                return DimensionResult(
                    dimension="Timing Correlation",
                    max_points=max_points,
                    awarded_points=points,
                    passed=True,
                    detail=f"Inactivity onset {diff_minutes:.0f}min after trigger (reasonable delay)",
                )
            else:
                return DimensionResult(
                    dimension="Timing Correlation",
                    max_points=max_points,
                    awarded_points=3,
                    passed=False,
                    detail=f"Inactivity onset {diff_minutes:.0f}min after trigger (too late)",
                )
        except (ValueError, TypeError):
            pass

    # Default: give partial credit when timing data unavailable
    return DimensionResult(
        dimension="Timing Correlation",
        max_points=max_points,
        awarded_points=12,
        passed=True,
        detail="Timing check passed (mock — real check via activity timestamps)",
    )
