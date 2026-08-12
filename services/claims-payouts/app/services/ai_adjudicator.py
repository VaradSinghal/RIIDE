import os
import random
import pandas as pd
import numpy as np
from sklearn.ensemble import GradientBoostingClassifier
import logging

logger = logging.getLogger(__name__)

DATA_DIR = os.path.join(os.path.dirname(__file__), "..", "..", "data")
CSV_PATH = os.path.join(DATA_DIR, "historical_adjudications.csv")

class AIAdjudicator:
    def __init__(self):
        self.model = GradientBoostingClassifier(n_estimators=50, random_state=42)
        self.is_trained = False
        
        if not os.path.exists(DATA_DIR):
            os.makedirs(DATA_DIR)

    def _generate_synthetic_data(self, n_rows=10000):
        """Generate realistic synthetic training data for claims adjudication."""
        logger.info(f"Generating {n_rows} rows of synthetic adjudication data...")
        data = []
        for _ in range(n_rows):
            fraud_score = random.uniform(0, 100) # Higher is more trusted here based on our score, wait, trust score = 100 is best.
            weather_severity = random.choice([0, 1, 2, 3]) # 0: none, 1: low, 2: med, 3: high
            amount = random.uniform(500, 5000)
            past_claims = random.randint(0, 5)
            
            # Action: 0 = auto_approve, 1 = manual_review, 2 = reject
            if fraud_score < 40:
                action = 2 # Reject due to high fraud suspicion
            elif fraud_score < 70 or weather_severity < 2 or amount > 3000:
                action = 1 # Manual review
            else:
                action = 0 # Auto approve
                
            # Add some noise to make model learn soft boundaries
            if random.random() < 0.05:
                action = random.choice([0, 1, 2])
                
            data.append([fraud_score, weather_severity, amount, past_claims, action])
            
        df = pd.DataFrame(data, columns=["trust_score", "weather_severity", "claim_amount", "past_claims", "action"])
        df.to_csv(CSV_PATH, index=False)
        logger.info(f"Generated adjudication data at {CSV_PATH}")

    def train_model(self):
        """Train the model."""
        if not os.path.exists(CSV_PATH):
            self._generate_synthetic_data()
            
        df = pd.read_csv(CSV_PATH)
        X = df.drop("action", axis=1)
        y = df["action"]
        
        self.model.fit(X, y)
        self.is_trained = True
        logger.info("AI Adjudicator model trained successfully.")

    def adjudicate_claim(self, trust_score: float, severity_str: str, claim_amount: float, past_claims: int) -> dict:
        """Run AI inference for claim adjudication."""
        if not self.is_trained:
            self.train_model()
            
        sev_map = {"none": 0, "low": 1, "medium": 2, "high": 3}
        sev_val = sev_map.get(severity_str.lower(), 1)
        
        features = np.array([[trust_score, sev_val, claim_amount, past_claims]])
        prediction = self.model.predict(features)[0]
        probs = self.model.predict_proba(features)[0]
        
        action_map = {0: "auto_approve", 1: "manual_review", 2: "reject"}
        action = action_map[prediction]
        
        confidence = round(max(probs) * 100, 1)
        
        # Explainability
        importances = self.model.feature_importances_
        feature_names = ["Trust Score", "Weather Severity", "Claim Amount", "Past Claims History"]
        
        explanation = {
            "ai_action": action,
            "confidence_pct": confidence,
            "reasoning_factors": [
                {"factor": name, "importance": round(imp * 100, 1)}
                for name, imp in zip(feature_names, importances)
            ]
        }
        
        return explanation

ai_adjudicator = AIAdjudicator()
