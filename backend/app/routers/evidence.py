"""
Evidence profile router — Layer 3: Partner/Government API.
This is the consent-gated REST endpoint that external partners would call.
"""
import json
from fastapi import APIRouter, HTTPException, Header, Request
from typing import Optional
from app.database import get_db
from app.models.schemas import EvidenceProfileResponse, MetricsModel, ConsentUpdate
from app.services.evidence_computer import compute_evidence_summary

router = APIRouter(prefix="/api/v1/evidence-profile", tags=["evidence-profile"])


@router.get("/{user_id}", response_model=EvidenceProfileResponse)
async def get_evidence_profile(
    user_id: str,
    x_user_consent: Optional[str] = Header(None),
):
    """
    Get the evidence profile for a shopkeeper.
    Requires X-User-Consent: true header — returns 403 if consent is revoked.
    This is the single most important trust signal in the demo.
    """
    with get_db() as conn:
        user = conn.execute("SELECT id FROM users WHERE id = ?", (user_id,)).fetchone()
        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        summary_row = conn.execute(
            "SELECT * FROM evidence_summaries WHERE user_id = ?", (user_id,)
        ).fetchone()

        if not summary_row:
            summary = compute_evidence_summary(user_id)
            summary_row = conn.execute(
                "SELECT * FROM evidence_summaries WHERE user_id = ?", (user_id,)
            ).fetchone()

        consent_db = bool(summary_row["has_user_consented_to_share"])
        consent_header = x_user_consent and x_user_consent.lower() == "true"

        if not consent_db or not consent_header:
            raise HTTPException(
                status_code=403,
                detail={
                    "error": "consent_required",
                    "message": "User has not consented to share their financial evidence profile. "
                               "Both the user's consent setting AND the X-User-Consent: true header must be active.",
                    "has_user_consented_to_share": consent_db,
                    "x_user_consent_header": x_user_consent,
                }
            )

        factors = json.loads(summary_row["explainable_factors"]) if summary_row["explainable_factors"] else []

        return EvidenceProfileResponse(
            user_id=user_id,
            has_user_consented_to_share=True,
            profile_generated_at=summary_row["profile_generated_at"],
            metrics=MetricsModel(
                avg_daily_sales=summary_row["avg_daily_sales"],
                sales_volatility=summary_row["sales_volatility"],
                days_with_transactions=summary_row["days_with_transactions"],
                cash_buffer_days=summary_row["cash_buffer_days"],
            ),
            explainable_factors=factors,
            readiness_summary=summary_row["readiness_summary"],
        )


@router.patch("/{user_id}/consent")
async def update_consent(user_id: str, update: ConsentUpdate):
    """Update the user's consent preference for data sharing."""
    with get_db() as conn:
        user = conn.execute("SELECT id FROM users WHERE id = ?", (user_id,)).fetchone()
        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        existing = conn.execute(
            "SELECT id FROM evidence_summaries WHERE user_id = ?", (user_id,)
        ).fetchone()

        if existing:
            conn.execute("""
                UPDATE evidence_summaries
                SET has_user_consented_to_share = ?
                WHERE user_id = ?
            """, (int(update.has_user_consented_to_share), user_id))
        else:
            compute_evidence_summary(user_id)
            conn.execute("""
                UPDATE evidence_summaries
                SET has_user_consented_to_share = ?
                WHERE user_id = ?
            """, (int(update.has_user_consented_to_share), user_id))

        return {
            "user_id": user_id,
            "has_user_consented_to_share": update.has_user_consented_to_share,
            "message": "Consent updated. API will {} return data for this user.".format(
                "now" if update.has_user_consented_to_share else "no longer"
            )
        }


@router.get("/{user_id}/full")
async def get_full_evidence_profile(user_id: str, x_user_consent: Optional[str] = Header(None)):
    """Get the full evidence profile including all computed metrics (for Layer 2 UI)."""
    with get_db() as conn:
        user = conn.execute("SELECT id FROM users WHERE id = ?", (user_id,)).fetchone()
        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        summary_row = conn.execute(
            "SELECT * FROM evidence_summaries WHERE user_id = ?", (user_id,)
        ).fetchone()

        if not summary_row:
            summary = compute_evidence_summary(user_id)
            summary_row = conn.execute(
                "SELECT * FROM evidence_summaries WHERE user_id = ?", (user_id,)
            ).fetchone()

        consent_db = bool(summary_row["has_user_consented_to_share"])
        consent_header = x_user_consent and x_user_consent.lower() == "true"

        if not consent_db or not consent_header:
            raise HTTPException(
                status_code=403,
                detail={
                    "error": "consent_required",
                    "message": "User has not consented to share their financial evidence profile.",
                }
            )

        factors = json.loads(summary_row["explainable_factors"]) if summary_row["explainable_factors"] else []

        return {
            "user_id": user_id,
            "has_user_consented_to_share": True,
            "profile_generated_at": summary_row["profile_generated_at"],
            "metrics": {
                "avg_daily_sales": summary_row["avg_daily_sales"],
                "avg_daily_expenses": summary_row["avg_daily_expenses"],
                "sales_volatility": summary_row["sales_volatility"],
                "days_with_transactions": summary_row["days_with_transactions"],
                "cash_buffer_days": summary_row["cash_buffer_days"],
                "net_cash_position": summary_row["net_cash_position"],
                "total_sales_30d": summary_row["total_sales_30d"],
                "total_purchases_30d": summary_row["total_purchases_30d"],
                "total_expenses_30d": summary_row["total_expenses_30d"],
                "total_withdrawals_30d": summary_row["total_withdrawals_30d"],
            },
            "explainable_factors": factors,
            "readiness_summary": summary_row["readiness_summary"],
            "top_category": summary_row["top_category"],
            "top_category_margin": summary_row["top_category_margin"],
            "killer_insight": summary_row["killer_insight"],
        }
