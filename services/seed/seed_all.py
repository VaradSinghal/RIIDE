"""
GigKavach — Seed Data Script
Populates the database with sample workers, zones, policies, claims, earnings, and ledger entries.
Run after docker-compose up.
"""

import sys
import os
import uuid
import random
from datetime import datetime, date, timedelta
from decimal import Decimal

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker

from shared.database import Base


def get_sync_url():
    host = os.getenv("POSTGRES_HOST", "localhost")
    port = os.getenv("POSTGRES_PORT", "5432")
    db = os.getenv("POSTGRES_DB", "gigkavach")
    user = os.getenv("POSTGRES_USER", "gigkavach")
    pwd = os.getenv("POSTGRES_PASSWORD", "gigkavach_dev_2026")
    return f"postgresql://{user}:{pwd}@{host}:{port}/{db}"


# ── Sample Data ──

WORKERS = [
    {"worker_id": "GK-CHN-001", "name": "Ramesh Kumar", "phone": "+91-9876543210", "city": "Chennai", "h3_zone": "872a10d83ffffff", "primary_platform": "zomato", "secondary_platform": "swiggy", "vehicle_type": "bike", "avg_daily_hours": 10.5, "experience_weeks": 24, "avg_daily_income": 720.0, "avg_weekly_income": 4320.0},
    {"worker_id": "GK-CHN-002", "name": "Priya Devi", "phone": "+91-9876543211", "city": "Chennai", "h3_zone": "872a10d85ffffff", "primary_platform": "swiggy", "secondary_platform": None, "vehicle_type": "bike", "avg_daily_hours": 8.0, "experience_weeks": 16, "avg_daily_income": 580.0, "avg_weekly_income": 3480.0},
    {"worker_id": "GK-CHN-003", "name": "Suresh Babu", "phone": "+91-9876543212", "city": "Chennai", "h3_zone": "872a10d87ffffff", "primary_platform": "zepto", "secondary_platform": "zomato", "vehicle_type": "bike", "avg_daily_hours": 11.0, "experience_weeks": 32, "avg_daily_income": 800.0, "avg_weekly_income": 4800.0},
    {"worker_id": "GK-CHN-004", "name": "Lakshmi Narayanan", "phone": "+91-9876543213", "city": "Chennai", "h3_zone": "872a10d81ffffff", "primary_platform": "zomato", "secondary_platform": "swiggy", "vehicle_type": "bike", "avg_daily_hours": 9.0, "experience_weeks": 8, "avg_daily_income": 650.0, "avg_weekly_income": 3900.0},
    {"worker_id": "GK-DEL-001", "name": "Amit Singh", "phone": "+91-9876543214", "city": "Delhi", "h3_zone": "872a11a01ffffff", "primary_platform": "zomato", "secondary_platform": "swiggy", "vehicle_type": "bike", "avg_daily_hours": 10.0, "experience_weeks": 20, "avg_daily_income": 750.0, "avg_weekly_income": 4500.0},
    {"worker_id": "GK-DEL-002", "name": "Pooja Sharma", "phone": "+91-9876543215", "city": "Delhi", "h3_zone": "872a11a03ffffff", "primary_platform": "swiggy", "secondary_platform": "zepto", "vehicle_type": "bike", "avg_daily_hours": 7.5, "experience_weeks": 12, "avg_daily_income": 550.0, "avg_weekly_income": 3300.0},
    {"worker_id": "GK-DEL-003", "name": "Rajesh Verma", "phone": "+91-9876543216", "city": "Delhi", "h3_zone": "872a11a05ffffff", "primary_platform": "zepto", "secondary_platform": None, "vehicle_type": "bike", "avg_daily_hours": 9.5, "experience_weeks": 28, "avg_daily_income": 680.0, "avg_weekly_income": 4080.0},
    {"worker_id": "GK-MUM-001", "name": "Vishal Patil", "phone": "+91-9876543217", "city": "Mumbai", "h3_zone": "872a12b01ffffff", "primary_platform": "zomato", "secondary_platform": "swiggy", "vehicle_type": "bike", "avg_daily_hours": 11.0, "experience_weeks": 36, "avg_daily_income": 850.0, "avg_weekly_income": 5100.0},
    {"worker_id": "GK-MUM-002", "name": "Sneha More", "phone": "+91-9876543218", "city": "Mumbai", "h3_zone": "872a12b03ffffff", "primary_platform": "swiggy", "secondary_platform": None, "vehicle_type": "bike", "avg_daily_hours": 8.5, "experience_weeks": 14, "avg_daily_income": 620.0, "avg_weekly_income": 3720.0},
    {"worker_id": "GK-MUM-003", "name": "Rahul Desai", "phone": "+91-9876543219", "city": "Mumbai", "h3_zone": "872a12b05ffffff", "primary_platform": "zepto", "secondary_platform": "zomato", "vehicle_type": "bike", "avg_daily_hours": 10.0, "experience_weeks": 22, "avg_daily_income": 730.0, "avg_weekly_income": 4380.0},
]

H3_ZONES = [
    {"h3_index": "872a10d83ffffff", "city": "Chennai", "zone_name": "Adyar", "risk_score": 62, "risk_label": "Moderate", "flood_prone": True, "weather_risk_factor": 0.45},
    {"h3_index": "872a10d85ffffff", "city": "Chennai", "zone_name": "T. Nagar", "risk_score": 35, "risk_label": "Low", "flood_prone": False, "weather_risk_factor": 0.25},
    {"h3_index": "872a10d87ffffff", "city": "Chennai", "zone_name": "Velachery", "risk_score": 78, "risk_label": "High", "flood_prone": True, "weather_risk_factor": 0.60},
    {"h3_index": "872a10d81ffffff", "city": "Chennai", "zone_name": "Anna Nagar", "risk_score": 28, "risk_label": "Low", "flood_prone": False, "weather_risk_factor": 0.20},
    {"h3_index": "872a10d89ffffff", "city": "Chennai", "zone_name": "OMR", "risk_score": 45, "risk_label": "Moderate", "flood_prone": False, "weather_risk_factor": 0.35},
    {"h3_index": "872a11a01ffffff", "city": "Delhi", "zone_name": "Connaught Place", "risk_score": 55, "risk_label": "Moderate", "flood_prone": False, "weather_risk_factor": 0.40},
    {"h3_index": "872a11a03ffffff", "city": "Delhi", "zone_name": "Dwarka", "risk_score": 72, "risk_label": "High", "flood_prone": True, "weather_risk_factor": 0.55},
    {"h3_index": "872a11a05ffffff", "city": "Delhi", "zone_name": "Rohini", "risk_score": 68, "risk_label": "Moderate", "flood_prone": True, "weather_risk_factor": 0.50},
    {"h3_index": "872a11a07ffffff", "city": "Delhi", "zone_name": "Saket", "risk_score": 30, "risk_label": "Low", "flood_prone": False, "weather_risk_factor": 0.22},
    {"h3_index": "872a11a09ffffff", "city": "Delhi", "zone_name": "Karol Bagh", "risk_score": 48, "risk_label": "Moderate", "flood_prone": False, "weather_risk_factor": 0.38},
    {"h3_index": "872a12b01ffffff", "city": "Mumbai", "zone_name": "Bandra", "risk_score": 58, "risk_label": "Moderate", "flood_prone": False, "weather_risk_factor": 0.42},
    {"h3_index": "872a12b03ffffff", "city": "Mumbai", "zone_name": "Andheri", "risk_score": 65, "risk_label": "Moderate", "flood_prone": True, "weather_risk_factor": 0.48},
    {"h3_index": "872a12b05ffffff", "city": "Mumbai", "zone_name": "Kurla", "risk_score": 82, "risk_label": "High", "flood_prone": True, "weather_risk_factor": 0.65},
    {"h3_index": "872a12b07ffffff", "city": "Mumbai", "zone_name": "Dadar", "risk_score": 52, "risk_label": "Moderate", "flood_prone": False, "weather_risk_factor": 0.40},
    {"h3_index": "872a12b09ffffff", "city": "Mumbai", "zone_name": "Powai", "risk_score": 38, "risk_label": "Low", "flood_prone": False, "weather_risk_factor": 0.28},
]


def seed_all():
    engine = create_engine(get_sync_url(), echo=True)

    # Import all models to register them
    sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'worker-earnings'))
    sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'risk-pricing'))
    sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'claims-payouts'))
    sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'trust-fraud'))

    # Create all tables
    Base.metadata.create_all(engine)

    Session = sessionmaker(bind=engine)
    session = Session()

    try:
        # ── 1. Seed Workers ──
        print("\n📋 Seeding workers...")
        for w in WORKERS:
            session.execute(text("""
                INSERT INTO workers (worker_id, name, phone, city, h3_zone, primary_platform,
                    secondary_platform, vehicle_type, avg_daily_hours, experience_weeks,
                    avg_daily_income, avg_weekly_income)
                VALUES (:worker_id, :name, :phone, :city, :h3_zone, :primary_platform,
                    :secondary_platform, :vehicle_type, :avg_daily_hours, :experience_weeks,
                    :avg_daily_income, :avg_weekly_income)
                ON CONFLICT (worker_id) DO NOTHING
            """), w)
        print(f"   ✅ {len(WORKERS)} workers seeded")

        # ── 2. Seed H3 Zones ──
        print("\n🗺️  Seeding H3 zones...")
        for z in H3_ZONES:
            session.execute(text("""
                INSERT INTO h3_zones (h3_index, city, zone_name, risk_score, risk_label,
                    flood_prone, weather_risk_factor)
                VALUES (:h3_index, :city, :zone_name, :risk_score, :risk_label,
                    :flood_prone, :weather_risk_factor)
                ON CONFLICT (h3_index) DO NOTHING
            """), z)
        print(f"   ✅ {len(H3_ZONES)} H3 zones seeded")

        # ── 3. Seed Earnings Log (30 days per worker) ──
        print("\n💰 Seeding earnings log...")
        earnings_count = 0
        platforms = ["zomato", "swiggy", "zepto"]
        for w in WORKERS:
            for day_offset in range(30):
                d = date.today() - timedelta(days=day_offset)
                platform = w["primary_platform"]
                hours = round(random.uniform(6, 12), 1)
                orders = random.randint(8, 25)
                earnings = round(random.uniform(400, 1100), 2)
                incentives = round(random.uniform(0, 150), 2)
                tips = round(random.uniform(0, 80), 2)

                session.execute(text("""
                    INSERT INTO earnings_log (worker_id, platform, date, hours_worked,
                        orders_completed, gross_earnings, incentives, tips)
                    VALUES (:worker_id, :platform, :date, :hours, :orders,
                        :earnings, :incentives, :tips)
                """), {
                    "worker_id": w["worker_id"], "platform": platform, "date": d,
                    "hours": hours, "orders": orders, "earnings": earnings,
                    "incentives": incentives, "tips": tips,
                })
                earnings_count += 1

                # Some workers also earn on secondary platform
                if w.get("secondary_platform") and random.random() > 0.5:
                    session.execute(text("""
                        INSERT INTO earnings_log (worker_id, platform, date, hours_worked,
                            orders_completed, gross_earnings, incentives, tips)
                        VALUES (:worker_id, :platform, :date, :hours, :orders,
                            :earnings, :incentives, :tips)
                    """), {
                        "worker_id": w["worker_id"], "platform": w["secondary_platform"],
                        "date": d, "hours": round(random.uniform(2, 5), 1),
                        "orders": random.randint(3, 10),
                        "earnings": round(random.uniform(150, 500), 2),
                        "incentives": round(random.uniform(0, 50), 2),
                        "tips": round(random.uniform(0, 30), 2),
                    })
                    earnings_count += 1
        print(f"   ✅ {earnings_count} earnings entries seeded")

        # ── 4. Seed Policies ──
        print("\n📜 Seeding policies...")
        policy_count = 0
        for w in WORKERS:
            policy_id = f"POL-{uuid.uuid4().hex[:8].upper()}"
            weekly_income = w["avg_weekly_income"]
            session.execute(text("""
                INSERT INTO policies (policy_id, worker_id, h3_zone, tier, weekly_premium,
                    coverage_percentage, coverage_ceiling, start_date, end_date, status)
                VALUES (:policy_id, :worker_id, :h3_zone, :tier, :premium,
                    :coverage_pct, :ceiling, :start_date, :end_date, 'active')
                ON CONFLICT (policy_id) DO NOTHING
            """), {
                "policy_id": policy_id, "worker_id": w["worker_id"],
                "h3_zone": w["h3_zone"], "tier": "standard",
                "premium": round(35 + random.uniform(5, 25), 2),
                "coverage_pct": 70,
                "ceiling": round(weekly_income * 0.7, 2),
                "start_date": date.today() - timedelta(days=14),
                "end_date": date.today() + timedelta(days=14),
            })
            policy_count += 1
        print(f"   ✅ {policy_count} policies seeded")

        # ── 5. Seed Claims ──
        print("\n📝 Seeding sample claims...")
        claim_states = [
            ("TriggerDetected", "heavy_rainfall"),
            ("FNOLCreated", "severe_aqi"),
            ("FraudAdjudicated", "extreme_heat"),
            ("PayoutCompleted", "flooding"),
            ("PayoutCompleted", "civic_disruption"),
        ]
        for i, (state, trigger) in enumerate(claim_states):
            claim_id = f"CLM-SEED-{i+1:03d}"
            worker = WORKERS[i % len(WORKERS)]
            session.execute(text("""
                INSERT INTO claims (claim_id, worker_id, h3_zone, trigger_type,
                    trigger_data, current_state, payout_amount, confidence_score)
                VALUES (:claim_id, :worker_id, :h3_zone, :trigger_type,
                    :trigger_data, :state, :payout, :confidence)
                ON CONFLICT (claim_id) DO NOTHING
            """), {
                "claim_id": claim_id, "worker_id": worker["worker_id"],
                "h3_zone": worker["h3_zone"], "trigger_type": trigger,
                "trigger_data": '{"seeded": true}', "state": state,
                "payout": round(random.uniform(200, 600), 2) if "Payout" in state else None,
                "confidence": random.randint(70, 95) if state != "TriggerDetected" else None,
            })

            # Add events for each claim
            events_for_state = {
                "TriggerDetected": ["TriggerDetected"],
                "FNOLCreated": ["TriggerDetected", "FNOLCreated"],
                "FraudAdjudicated": ["TriggerDetected", "FNOLCreated", "FraudAdjudicated"],
                "PayoutCompleted": ["TriggerDetected", "FNOLCreated", "FraudAdjudicated",
                                     "ReserveSet", "PayoutInitiated", "PayoutCompleted"],
            }
            for evt in events_for_state.get(state, []):
                session.execute(text("""
                    INSERT INTO claim_events (claim_id, event_type, event_data)
                    VALUES (:claim_id, :event_type, :event_data)
                """), {
                    "claim_id": claim_id, "event_type": evt,
                    "event_data": '{"seeded": true}',
                })
        print(f"   ✅ {len(claim_states)} claims with events seeded")

        # ── 6. Seed Ledger (claims reserve fund) ──
        print("\n💳 Seeding ledger entries...")
        # Seed the claims reserve with ₹5,00,000
        session.execute(text("""
            INSERT INTO ledger_entries (account_id, debit, credit, txn_ref,
                idempotency_key, description)
            VALUES ('funding_source', 500000, 0, 'SEED-FUND-001',
                'seed-fund-debit-001', 'Initial fund disbursement')
            ON CONFLICT (idempotency_key) DO NOTHING
        """))
        session.execute(text("""
            INSERT INTO ledger_entries (account_id, debit, credit, txn_ref,
                idempotency_key, description)
            VALUES ('claims_reserve', 0, 500000, 'SEED-FUND-001',
                'seed-fund-credit-001', 'Initial claims reserve funding')
            ON CONFLICT (idempotency_key) DO NOTHING
        """))
        print("   ✅ Claims reserve seeded with ₹5,00,000")

        session.commit()
        print("\n🎉 All seed data inserted successfully!")

    except Exception as e:
        session.rollback()
        print(f"\n❌ Seed failed: {e}")
        raise
    finally:
        session.close()


if __name__ == "__main__":
    seed_all()
