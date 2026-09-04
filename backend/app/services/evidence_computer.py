"""
Evidence summary computer — derives the Evidence Profile from raw ledger entries.
This single computation feeds both Layer 2 (UI) and Layer 3 (API).
"""
import json
import math
from datetime import datetime, timedelta
from app.database import get_db


def compute_evidence_summary(user_id: str) -> dict:
    """Compute evidence summary from the user's ledger entries."""
    with get_db() as conn:
        thirty_days_ago = (datetime.utcnow() - timedelta(days=30)).isoformat()

        rows = conn.execute("""
            SELECT entry_type, amount, created_at, category
            FROM ledger_entries
            WHERE user_id = ? AND confirmed = 1 AND created_at >= ?
            ORDER BY created_at ASC
        """, (user_id, thirty_days_ago)).fetchall()

        if not rows:
            # Persist the empty summary too, so callers that re-read the row
            # (e.g. the evidence endpoint) always find one and never crash on a
            # missing record for a user who simply has no confirmed entries yet.
            summary = _empty_summary(user_id)
            _upsert_summary(conn, user_id, summary)
            return summary

        entries = [dict(r) for r in rows]
        today = datetime.utcnow().date()

        sales = [e for e in entries if e["entry_type"] == "sale"]
        purchases = [e for e in entries if e["entry_type"] == "purchase"]
        expenses = [e for e in entries if e["entry_type"] == "expense"]
        withdrawals = [e for e in entries if e["entry_type"] == "withdrawal"]

        total_sales = sum(e["amount"] for e in sales)
        total_purchases = sum(e["amount"] for e in purchases)
        total_expenses = sum(e["amount"] for e in expenses)
        total_withdrawals = sum(e["amount"] for e in withdrawals)

        days_with_txns = len(set(datetime.fromisoformat(e["created_at"]).date() for e in entries if e["created_at"]))
        avg_daily_sales = round(total_sales / max(days_with_txns, 1), 2)
        avg_daily_expenses = round((total_purchases + total_expenses + total_withdrawals) / max(days_with_txns, 1), 2)

        net_cash = total_sales - total_purchases - total_expenses - total_withdrawals

        weekly_sales = {}
        for e in sales:
            if e["created_at"]:
                week = datetime.fromisoformat(e["created_at"]).isocalendar()[1]
                weekly_sales[week] = weekly_sales.get(week, 0) + e["amount"]

        sales_volatility = _compute_volatility(list(weekly_sales.values()))

        cash_buffer_days = 0
        if avg_daily_expenses > 0:
            cash_buffer_days = int(net_cash / avg_daily_expenses) if net_cash > 0 else 0

        top_category, top_category_margin = _compute_top_category(sales, purchases)

        explainable_factors = _build_factors(days_with_txns, sales_volatility, cash_buffer_days, net_cash, entries)
        readiness_summary = _build_readiness(avg_daily_sales, sales_volatility, days_with_txns, cash_buffer_days, net_cash)
        killer_insight = _build_insight(entries, total_sales, total_withdrawals, top_category, top_category_margin)

        summary = {
            "user_id": user_id,
            "avg_daily_sales": avg_daily_sales,
            "avg_daily_expenses": avg_daily_expenses,
            "sales_volatility": sales_volatility,
            "days_with_transactions": days_with_txns,
            "cash_buffer_days": cash_buffer_days,
            "net_cash_position": round(net_cash, 2),
            "total_sales_30d": round(total_sales, 2),
            "total_purchases_30d": round(total_purchases, 2),
            "total_expenses_30d": round(total_expenses, 2),
            "total_withdrawals_30d": round(total_withdrawals, 2),
            "explainable_factors": explainable_factors,
            "readiness_summary": readiness_summary,
            "top_category": top_category or "",
            "top_category_margin": round(top_category_margin, 2) if top_category_margin else 0,
            "killer_insight": killer_insight,
        }

        _upsert_summary(conn, user_id, summary)
        return summary


def _compute_volatility(weekly_values: list[float]) -> str:
    if len(weekly_values) < 2:
        return "low"
    mean = sum(weekly_values) / len(weekly_values)
    if mean == 0:
        return "low"
    variance = sum((v - mean) ** 2 for v in weekly_values) / len(weekly_values)
    cv = math.sqrt(variance) / mean
    if cv < 0.2:
        return "low"
    elif cv < 0.4:
        return "medium"
    return "high"


def _compute_top_category(sales: list[dict], purchases: list[dict]) -> tuple:
    category_sales = {}
    category_purchases = {}
    for e in sales:
        cat = e.get("category") or "other"
        category_sales[cat] = category_sales.get(cat, 0) + e["amount"]
    for e in purchases:
        cat = e.get("category") or "other"
        category_purchases[cat] = category_purchases.get(cat, 0) + e["amount"]

    best_cat = None
    best_margin = 0
    for cat, rev in category_sales.items():
        cost = category_purchases.get(cat, 0)
        if rev > 0:
            margin = ((rev - cost) / rev) * 100
            if margin > best_margin:
                best_margin = margin
                best_cat = cat

    return best_cat, best_margin


def _build_factors(days: int, volatility: str, buffer_days: int, net_cash: float, entries: list) -> list[str]:
    factors = []
    consistency_pct = round((days / 30) * 100)
    factors.append(f"Recorded transactions on {consistency_pct}% of days in last 30 days ({days}/30 days)")

    if volatility == "low":
        factors.append("Sales variance < 20% week-to-week — stable income pattern")
    elif volatility == "medium":
        factors.append("Sales variance 20-40% week-to-week — moderate fluctuation")
    else:
        factors.append("Sales variance > 40% week-to-week — high fluctuation, may indicate seasonal business")

    if buffer_days >= 7:
        factors.append(f"Positive cash buffer: ~{buffer_days} days of expenses covered")
    elif buffer_days >= 3:
        factors.append(f"Moderate cash buffer: ~{buffer_days} days of expenses covered")
    elif buffer_days > 0:
        factors.append(f"Low cash buffer: only ~{buffer_days} days of expenses covered")
    else:
        factors.append("No cash buffer — expenses exceed or match income")

    if net_cash > 0:
        factors.append("No cash shortfalls predicted in next 7 days")
    else:
        factors.append("Cash shortfall risk — expenses trending above income")

    return factors


def _build_readiness(avg_sales: float, volatility: str, days: int, buffer: int, net_cash: float) -> str:
    if days >= 20 and volatility == "low" and net_cash > 0 and buffer >= 5:
        loan_range = "PKR 25,000-50,000"
        if avg_sales > 5000:
            loan_range = "PKR 50,000-100,000"
        return (f"This business shows consistent daily activity with stable cash flow. "
                f"Suitable for micro-loan {loan_range}.")
    elif days >= 15 and net_cash > 0:
        return ("This business shows moderate activity with some consistency. "
                "May qualify for micro-loan PKR 15,000-25,000 with additional verification.")
    elif days >= 7:
        return ("This business has some recorded activity but needs more consistency "
                "before loan readiness can be assessed. Encourage regular daily recording.")
    else:
        return ("Insufficient transaction history to assess loan readiness. "
                "Need at least 15-20 days of recorded transactions for a meaningful assessment.")


def _build_insight(entries: list, total_sales: float, total_withdrawals: float,
                   top_cat: str, top_margin: float) -> str:
    if total_sales > 0 and total_withdrawals > 0:
        withdrawal_pct = (total_withdrawals / total_sales) * 100
        if withdrawal_pct > 50:
            return (f"You withdraw {withdrawal_pct:.0f}% of daily sales for household expenses. "
                    f"Consider setting aside a fixed daily amount for ghar kharch to build business savings.")

    if top_cat and top_margin:
        return f"Your margin on {top_cat} is {top_margin:.0f}% — this is your strongest product category."

    return "Keep recording daily transactions to unlock business insights."


def _upsert_summary(conn, user_id: str, summary: dict):
    conn.execute("""
        INSERT INTO evidence_summaries
            (user_id, avg_daily_sales, avg_daily_expenses, sales_volatility,
             days_with_transactions, cash_buffer_days, net_cash_position,
             total_sales_30d, total_purchases_30d, total_expenses_30d,
             total_withdrawals_30d, explainable_factors, readiness_summary,
             top_category, top_category_margin, killer_insight,
             profile_generated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, datetime('now'))
        ON CONFLICT(user_id) DO UPDATE SET
            avg_daily_sales = excluded.avg_daily_sales,
            avg_daily_expenses = excluded.avg_daily_expenses,
            sales_volatility = excluded.sales_volatility,
            days_with_transactions = excluded.days_with_transactions,
            cash_buffer_days = excluded.cash_buffer_days,
            net_cash_position = excluded.net_cash_position,
            total_sales_30d = excluded.total_sales_30d,
            total_purchases_30d = excluded.total_purchases_30d,
            total_expenses_30d = excluded.total_expenses_30d,
            total_withdrawals_30d = excluded.total_withdrawals_30d,
            explainable_factors = excluded.explainable_factors,
            readiness_summary = excluded.readiness_summary,
            top_category = excluded.top_category,
            top_category_margin = excluded.top_category_margin,
            killer_insight = excluded.killer_insight,
            profile_generated_at = datetime('now')
    """, (
        user_id, summary["avg_daily_sales"], summary["avg_daily_expenses"],
        summary["sales_volatility"], summary["days_with_transactions"],
        summary["cash_buffer_days"], summary["net_cash_position"],
        summary["total_sales_30d"], summary["total_purchases_30d"],
        summary["total_expenses_30d"], summary["total_withdrawals_30d"],
        json.dumps(summary["explainable_factors"]),
        summary["readiness_summary"], summary["top_category"],
        summary["top_category_margin"], summary["killer_insight"],
    ))


def _empty_summary(user_id: str) -> dict:
    return {
        "user_id": user_id,
        "avg_daily_sales": 0,
        "avg_daily_expenses": 0,
        "sales_volatility": "unknown",
        "days_with_transactions": 0,
        "cash_buffer_days": 0,
        "net_cash_position": 0,
        "total_sales_30d": 0,
        "total_purchases_30d": 0,
        "total_expenses_30d": 0,
        "total_withdrawals_30d": 0,
        "explainable_factors": ["No transaction history yet — start recording daily transactions"],
        "readiness_summary": "Insufficient data to assess. Start recording your daily sales and expenses.",
        "top_category": "",
        "top_category_margin": 0,
        "killer_insight": "Start recording daily transactions to unlock business insights!",
    }
