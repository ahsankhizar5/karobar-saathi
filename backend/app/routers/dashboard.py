"""Dashboard router — provides shopkeeper's daily business overview."""
from fastapi import APIRouter, HTTPException
from datetime import datetime, timedelta
from app.database import get_db
from app.models.schemas import DashboardResponse
from app.services.evidence_computer import compute_evidence_summary

router = APIRouter(prefix="/api/v1/dashboard", tags=["dashboard"])


@router.get("/{user_id}", response_model=DashboardResponse)
async def get_dashboard(user_id: str):
    """Get dashboard data for a shopkeeper."""
    with get_db() as conn:
        user = conn.execute("SELECT id FROM users WHERE id = ?", (user_id,)).fetchone()
        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        today = datetime.utcnow().date().isoformat()
        today_entries = conn.execute("""
            SELECT entry_type, amount FROM ledger_entries
            WHERE user_id = ? AND date(created_at) = ? AND confirmed = 1
        """, (user_id, today)).fetchall()

        today_sales = sum(e["amount"] for e in today_entries if e["entry_type"] == "sale")
        today_expenses = sum(e["amount"] for e in today_entries if e["entry_type"] in
                             ("purchase", "expense", "withdrawal"))
        today_profit = today_sales - today_expenses

        weekly_trend = []
        for i in range(6, -1, -1):
            day = (datetime.utcnow() - timedelta(days=i)).date().isoformat()
            day_data = conn.execute("""
                SELECT entry_type, amount FROM ledger_entries
                WHERE user_id = ? AND date(created_at) = ? AND confirmed = 1
            """, (user_id, day)).fetchall()

            day_sales = sum(e["amount"] for e in day_data if e["entry_type"] == "sale")
            day_exp = sum(e["amount"] for e in day_data if e["entry_type"] in
                          ("purchase", "expense", "withdrawal"))
            day_label = (datetime.utcnow() - timedelta(days=i)).strftime("%a")
            weekly_trend.append({
                "day": day_label,
                "date": day,
                "sales": round(day_sales, 2),
                "expenses": round(day_exp, 2),
                "profit": round(day_sales - day_exp, 2),
            })

        all_time = conn.execute("""
            SELECT entry_type, amount FROM ledger_entries
            WHERE user_id = ? AND confirmed = 1
        """, (user_id,)).fetchall()

        total_in = sum(e["amount"] for e in all_time if e["entry_type"] == "sale")
        total_out = sum(e["amount"] for e in all_time if e["entry_type"] in
                        ("purchase", "expense", "withdrawal"))
        cash_position = total_in - total_out

        summary = compute_evidence_summary(user_id)

        return DashboardResponse(
            today_profit=round(today_profit, 2),
            today_sales=round(today_sales, 2),
            today_expenses=round(today_expenses, 2),
            weekly_trend=weekly_trend,
            cash_position=round(cash_position, 2),
            top_category=summary.get("top_category") or None,
            top_category_margin=summary.get("top_category_margin") or None,
            killer_insight=summary.get("killer_insight", "Keep recording daily transactions!"),
            total_entries_today=len(today_entries),
        )
