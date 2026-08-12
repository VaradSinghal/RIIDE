"""
GigKavach — Worker & Earnings: Boost Engine

Rule-based earnings boost recommendations.
Structured so an XGBoost model can replace the rules later
without changing the calling code.
"""

import random
from typing import Protocol
from dataclasses import dataclass


@dataclass
class BoostRecommendation:
    zone_name: str
    h3_index: str
    expected_hourly: float
    boost_pct: float
    reason: str
    confidence: float


class BoostModel(Protocol):
    """Interface for boost models — swap rule-based for XGBoost later."""
    def predict_top_zones(self, city: str, current_zone: str, n: int) -> list[BoostRecommendation]: ...


class RuleBasedBoostEngine:
    """
    Rule-based implementation.
    Uses time-of-day + zone demand patterns to recommend zones.
    """

    # Mock zone data (city → zones with base demand)
    ZONE_DATA = {
        "Chennai": [
            ("Adyar", "872a10d83ffffff", 75),
            ("T. Nagar", "872a10d85ffffff", 85),
            ("Velachery", "872a10d87ffffff", 70),
            ("Anna Nagar", "872a10d81ffffff", 80),
            ("OMR", "872a10d89ffffff", 90),
        ],
        "Delhi": [
            ("Connaught Place", "872a11a01ffffff", 90),
            ("Dwarka", "872a11a03ffffff", 65),
            ("Rohini", "872a11a05ffffff", 70),
            ("Saket", "872a11a07ffffff", 80),
            ("Karol Bagh", "872a11a09ffffff", 75),
        ],
        "Mumbai": [
            ("Bandra", "872a12b01ffffff", 95),
            ("Andheri", "872a12b03ffffff", 85),
            ("Kurla", "872a12b05ffffff", 70),
            ("Dadar", "872a12b07ffffff", 80),
            ("Powai", "872a12b09ffffff", 75),
        ],
    }

    def predict_top_zones(self, city: str, current_zone: str, n: int = 3) -> list[BoostRecommendation]:
        zones = self.ZONE_DATA.get(city, self.ZONE_DATA["Chennai"])
        import datetime
        hour = datetime.datetime.now().hour

        recommendations = []
        for name, h3_idx, base_demand in zones:
            # Time-based multiplier
            if 11 <= hour <= 14 or 18 <= hour <= 22:
                multiplier = random.uniform(1.2, 1.5)
                reason = "Peak dining hours — high order density"
            elif 8 <= hour <= 10:
                multiplier = random.uniform(0.9, 1.1)
                reason = "Morning breakfast demand"
            else:
                multiplier = random.uniform(0.6, 0.9)
                reason = "Off-peak — moderate demand"

            expected_hourly = round(base_demand * multiplier, 2)
            boost_pct = round((multiplier - 1.0) * 100, 1)

            recommendations.append(BoostRecommendation(
                zone_name=name,
                h3_index=h3_idx,
                expected_hourly=expected_hourly,
                boost_pct=max(boost_pct, 0),
                reason=reason,
                confidence=round(random.uniform(0.6, 0.95), 2),
            ))

        # Sort by expected hourly earnings, return top N
        recommendations.sort(key=lambda r: r.expected_hourly, reverse=True)
        return recommendations[:n]


# Singleton — swap for XGBoostBoostEngine in production
boost_engine: BoostModel = RuleBasedBoostEngine()
