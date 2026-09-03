"""Seed database with 3 demo profiles and realistic transaction data."""
import json
import random
from datetime import datetime, timedelta
from app.database import get_db, init_db


DEMO_PROFILES = [
    {
        "user": {
            "id": "shop_001",
            "name": "Ahmad Chai Wala",
            "business_type": "tea_stall",
            "business_name": "Ahmad Tea Stall",
            "phone": "0300-1234567",
        },
        "daily_sales_range": (3000, 5500),
        "daily_purchases_range": (800, 1500),
        "daily_withdrawal": 1200,
        "daily_expense": 300,
        "consistency": 0.85,
        "categories": ["chai", "biscuits", "snacks", "paratha"],
    },
    {
        "user": {
            "id": "shop_002",
            "name": "Bibi Naseem",
            "business_type": "kirana_store",
            "business_name": "Naseem General Store",
            "phone": "0321-9876543",
        },
        "daily_sales_range": (5000, 9000),
        "daily_purchases_range": (3000, 5500),
        "daily_withdrawal": 1500,
        "daily_expense": 500,
        "consistency": 0.93,
        "categories": ["groceries", "household", "snacks", "drinks"],
    },
    {
        "user": {
            "id": "shop_003",
            "name": "Fatima Silai",
            "business_type": "home_tailor",
            "business_name": "Fatima Stitching",
            "phone": "0333-5551234",
        },
        "daily_sales_range": (1500, 4000),
        "daily_purchases_range": (300, 800),
        "daily_withdrawal": 800,
        "daily_expense": 150,
        "consistency": 0.72,
        "categories": ["stitching", "alteration", "fabric", "buttons_thread"],
    },
]


TRANSCRIPT_TEMPLATES = {
    "sale": [
        "Aaj {amount} ki sale hui",
        "Aaj {amount} ki bikri hui",
        "{amount} ki kamai hui aaj",
        "{amount} rs ki sale",
    ],
    "purchase": [
        "Aaj {amount} ka maal khareeda",
        "{amount} ka stock liya",
        "{amount} ka saamaan khareeda",
    ],
    "expense": [
        "{amount} ka bill aaya",
        "{amount} kharcha hua",
        "{amount} ka kiraya diya",
    ],
    "withdrawal": [
        "{amount} ghar bheje",
        "Ghar ke liye {amount} nikaale",
        "{amount} ghar kharch",
    ],
}


def seed_database():
    """Populate the database with demo profiles and 30 days of transaction data."""
    init_db()
    with get_db() as conn:
        existing = conn.execute("SELECT COUNT(*) as cnt FROM users").fetchone()
        if existing["cnt"] > 0:
            print("Database already seeded, skipping.")
            return

        for profile in DEMO_PROFILES:
            user = profile["user"]
            conn.execute(
                "INSERT OR IGNORE INTO users (id, name, business_type, business_name, phone) VALUES (?, ?, ?, ?, ?)",
                (user["id"], user["name"], user["business_type"], user["business_name"], user["phone"])
            )

            random.seed(user["id"])
            today = datetime.utcnow()

            for day_offset in range(30):
                day = today - timedelta(days=day_offset)
                if random.random() > profile["consistency"]:
                    continue

                day_str = day.strftime("%Y-%m-%d")
                ts_base = day.replace(hour=random.randint(9, 12), minute=random.randint(0, 59))

                sale_amount = random.randint(*profile["daily_sales_range"])
                sale_cat = random.choice(profile["categories"])
                sale_template = random.choice(TRANSCRIPT_TEMPLATES["sale"])
                sale_transcript = sale_template.format(amount=sale_amount)
                conn.execute("""
                    INSERT INTO ledger_entries
                    (user_id, entry_type, amount, note, raw_transcript, confirmed, category, created_at)
                    VALUES (?, 'sale', ?, ?, ?, 1, ?, ?)
                """, (user["id"], sale_amount, f"{sale_cat} sale", sale_transcript, sale_cat,
                      ts_base.isoformat()))

                if random.random() > 0.3:
                    purchase_amount = random.randint(*profile["daily_purchases_range"])
                    purchase_cat = random.choice(profile["categories"])
                    purchase_template = random.choice(TRANSCRIPT_TEMPLATES["purchase"])
                    purchase_transcript = purchase_template.format(amount=purchase_amount)
                    ts_purchase = ts_base.replace(hour=random.randint(10, 14))
                    conn.execute("""
                        INSERT INTO ledger_entries
                        (user_id, entry_type, amount, note, raw_transcript, confirmed, category, created_at)
                        VALUES (?, 'purchase', ?, ?, ?, 1, ?, ?)
                    """, (user["id"], purchase_amount, f"{purchase_cat} stock",
                          purchase_transcript, purchase_cat, ts_purchase.isoformat()))

                if random.random() > 0.7:
                    expense_amount = random.randint(100, profile["daily_expense"] * 2)
                    expense_template = random.choice(TRANSCRIPT_TEMPLATES["expense"])
                    expense_transcript = expense_template.format(amount=expense_amount)
                    ts_expense = ts_base.replace(hour=random.randint(14, 17))
                    conn.execute("""
                        INSERT INTO ledger_entries
                        (user_id, entry_type, amount, note, raw_transcript, confirmed, category, created_at)
                        VALUES (?, 'expense', ?, ?, ?, 1, 'utilities', ?)
                    """, (user["id"], expense_amount, "Bill/Kharcha",
                          expense_transcript, ts_expense.isoformat()))

                if random.random() > 0.2:
                    withdrawal_amount = profile["daily_withdrawal"] + random.randint(-200, 200)
                    withdrawal_template = random.choice(TRANSCRIPT_TEMPLATES["withdrawal"])
                    withdrawal_transcript = withdrawal_template.format(amount=withdrawal_amount)
                    ts_withdrawal = ts_base.replace(hour=random.randint(17, 20))
                    conn.execute("""
                        INSERT INTO ledger_entries
                        (user_id, entry_type, amount, note, raw_transcript, confirmed, category, created_at)
                        VALUES (?, 'withdrawal', ?, ?, ?, 1, 'household', ?)
                    """, (user["id"], withdrawal_amount, "Ghar bheje",
                          withdrawal_transcript, ts_withdrawal.isoformat()))

            conn.execute("""
                INSERT INTO evidence_summaries (user_id, has_user_consented_to_share)
                VALUES (?, 1)
                ON CONFLICT(user_id) DO NOTHING
            """, (user["id"],))

    from app.services.evidence_computer import compute_evidence_summary
    for profile in DEMO_PROFILES:
        compute_evidence_summary(profile["user"]["id"])

    print(f"Seeded {len(DEMO_PROFILES)} demo profiles with 30 days of transaction data.")


if __name__ == "__main__":
    seed_database()
