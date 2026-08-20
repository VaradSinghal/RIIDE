import os
import random
import pandas as pd
import numpy as np
from sklearn.ensemble import RandomForestRegressor
import logging

logger = logging.getLogger(__name__)

DATA_DIR = os.path.join(os.path.dirname(__file__), "..", "..", "data")
CSV_PATH = os.path.join(DATA_DIR, "historical_policies.csv")

class AIUnderwriter:
    def __init__(self):
        self.model = RandomForestRegressor(n_estimators=50, random_state=42)
        self.is_trained = False
        
        if not os.path.exists(DATA_DIR):
            os.makedirs(DATA_DIR)

    def _generate_synthetic_data(self, n_rows=10000):
        """Generate realistic synthetic training data."""
        logger.info(f"Generating {n_rows} rows of synthetic underwriting data...")
        data = []
        for _ in range(n_rows):
            zone_risk = random.uniform(10, 100)
            weather_risk = random.uniform(0.1, 1.0)
            experience_weeks = random.randint(0, 150)
            claim_rate = random.uniform(0, 0.5)
            vehicle_type_val = random.choice([0, 1, 2]) # 0: bike, 1: EV, 2: other
            worker_age = random.randint(18, 60)
            
            # Base formula for the target with some noise
            base = 15.0
            zone_adj = (zone_risk / 100) * 20
            weather_adj = weather_risk * 15
            veh_adj = 5 if vehicle_type_val == 0 else 2.5 if vehicle_type_val == 1 else 8
            age_adj = 8 if worker_age < 21 else 4 if worker_age < 25 else 0
            claims_adj = claim_rate * 15
            loyalty_disc = min(experience_weeks / 16 * 5, 12)
            safe_disc = 3 if zone_risk < 30 else 0
            
            # Phase 3: AI Underwriting with verified hours and income
            verified_daily_hours = random.uniform(4.0, 16.0)
            verified_daily_income = verified_daily_hours * random.uniform(40, 100)
            
            # Fatigue penalty: hours > 12 increases risk non-linearly
            fatigue_penalty = max(0, (verified_daily_hours - 12) ** 2) * 1.5
            # Moral hazard discount: higher stable income reduces risk
            stability_discount = min((verified_daily_income / 1500) * 4, 6)
            
            noise = random.uniform(-2, 2)
            
            premium = max(15.0, base + zone_adj + weather_adj + veh_adj + age_adj + claims_adj - loyalty_disc - safe_disc + fatigue_penalty - stability_discount + noise)
            
            data.append([zone_risk, weather_risk, experience_weeks, claim_rate, vehicle_type_val, worker_age, verified_daily_hours, verified_daily_income, premium])
            
        df = pd.DataFrame(data, columns=["zone_risk", "weather_risk", "experience_weeks", "claim_rate", "vehicle_type", "worker_age", "verified_daily_hours", "verified_daily_income", "target_premium"])
        df.to_csv(CSV_PATH, index=False)
        logger.info(f"Generated data at {CSV_PATH}")

    def train_model(self):
        """Train the Random Forest model."""
        if not os.path.exists(CSV_PATH):
            self._generate_synthetic_data()
            
        df = pd.read_csv(CSV_PATH)
        X = df.drop("target_premium", axis=1)
        y = df["target_premium"]
        
        self.model.fit(X, y)
        self.is_trained = True
        
        # Save a reference to X and y for scoring later if needed
        self.X_train = X
        self.y_train = y
        logger.info("AI Underwriting model trained successfully.")

    def predict_premium(self, zone_risk: float, weather_risk: float, experience_weeks: int, claim_rate: float, vehicle_type: str, worker_age: int, verified_daily_hours: float, verified_daily_income: float) -> dict:
        """Run AI inference for premium pricing."""
        if not self.is_trained:
            self.train_model()
            
        veh_val = 0 if vehicle_type.lower() == "bike" else 1 if vehicle_type.lower() == "ev" else 2
        
        features = np.array([[zone_risk, weather_risk, experience_weeks, claim_rate, veh_val, worker_age, verified_daily_hours, verified_daily_income]])
        
        prediction = self.model.predict(features)[0]
        
        # Feature importances for explainability
        importances = self.model.feature_importances_
        feature_names = ["Zone Risk", "Weather Severity", "Experience", "Claim Rate", "Vehicle Type", "Age", "Hours/Day", "Income/Day"]
        
        confidence = round(self.model.score(self.X_train, self.y_train) * 100, 1)
        
        explanation = {
            "predicted_premium": round(prediction, 2),
            "model_confidence": confidence,
            "feature_impacts": [
                {"feature": name, "impact_weight": round(imp * 100, 1)}
                for name, imp in zip(feature_names, importances)
            ]
        }
        
        return explanation

ai_underwriter = AIUnderwriter()
