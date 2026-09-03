"""Ledger router — CRUD operations for ledger entries."""
from fastapi import APIRouter, HTTPException
from datetime import datetime
from app.database import get_db
from app.models.schemas import (
    LedgerEntryCreate, LedgerEntryResponse, LedgerEntryConfirm, EntryType
)
from app.services.evidence_computer import compute_evidence_summary

router = APIRouter(prefix="/api/v1/ledger", tags=["ledger"])


@router.post("/", response_model=LedgerEntryResponse)
async def create_entry(entry: LedgerEntryCreate):
    """Create a new ledger entry (unconfirmed by default)."""
    with get_db() as conn:
        user = conn.execute("SELECT id FROM users WHERE id = ?", (entry.user_id,)).fetchone()
        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        cursor = conn.execute("""
            INSERT INTO ledger_entries (user_id, entry_type, amount, note, raw_transcript, confirmed, category)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        """, (
            entry.user_id, entry.entry_type.value, entry.amount,
            entry.note, entry.raw_transcript, int(entry.confirmed), entry.category
        ))
        entry_id = cursor.lastrowid

        row = conn.execute(
            "SELECT * FROM ledger_entries WHERE id = ?", (entry_id,)
        ).fetchone()

        return _row_to_response(row)


@router.get("/", response_model=list[LedgerEntryResponse])
async def list_entries(user_id: str, limit: int = 50, offset: int = 0):
    """List ledger entries for a user."""
    with get_db() as conn:
        rows = conn.execute("""
            SELECT * FROM ledger_entries
            WHERE user_id = ?
            ORDER BY created_at DESC
            LIMIT ? OFFSET ?
        """, (user_id, limit, offset)).fetchall()

        return [_row_to_response(r) for r in rows]


@router.get("/today", response_model=list[LedgerEntryResponse])
async def today_entries(user_id: str):
    """Get today's ledger entries."""
    today = datetime.utcnow().date().isoformat()
    with get_db() as conn:
        rows = conn.execute("""
            SELECT * FROM ledger_entries
            WHERE user_id = ? AND date(created_at) = ?
            ORDER BY created_at DESC
        """, (user_id, today)).fetchall()

        return [_row_to_response(r) for r in rows]


@router.patch("/{entry_id}/confirm", response_model=LedgerEntryResponse)
async def confirm_entry(entry_id: int, update: LedgerEntryConfirm):
    """Confirm a ledger entry, optionally correcting its fields."""
    with get_db() as conn:
        existing = conn.execute(
            "SELECT * FROM ledger_entries WHERE id = ?", (entry_id,)
        ).fetchone()
        if not existing:
            raise HTTPException(status_code=404, detail="Entry not found")

        entry_type = update.entry_type.value if update.entry_type else existing["entry_type"]
        amount = update.amount if update.amount is not None else existing["amount"]
        note = update.note if update.note is not None else existing["note"]
        category = update.category if update.category is not None else existing["category"]

        conn.execute("""
            UPDATE ledger_entries
            SET entry_type = ?, amount = ?, note = ?, category = ?, confirmed = 1
            WHERE id = ?
        """, (entry_type, amount, note, category, entry_id))

        row = conn.execute(
            "SELECT * FROM ledger_entries WHERE id = ?", (entry_id,)
        ).fetchone()
        response = _row_to_response(row)
        user_id = row["user_id"]

    compute_evidence_summary(user_id)
    return response


@router.delete("/{entry_id}")
async def delete_entry(entry_id: int):
    """Delete a ledger entry."""
    with get_db() as conn:
        existing = conn.execute(
            "SELECT * FROM ledger_entries WHERE id = ?", (entry_id,)
        ).fetchone()
        if not existing:
            raise HTTPException(status_code=404, detail="Entry not found")

        user_id = existing["user_id"]
        conn.execute("DELETE FROM ledger_entries WHERE id = ?", (entry_id,))

    compute_evidence_summary(user_id)
    return {"status": "deleted", "id": entry_id}


@router.post("/batch-confirm")
async def batch_confirm_entries(entries: list[LedgerEntryCreate]):
    """Create and immediately confirm multiple entries."""
    results = []
    user_ids = set()
    with get_db() as conn:
        for entry in entries:
            user = conn.execute("SELECT id FROM users WHERE id = ?", (entry.user_id,)).fetchone()
            if not user:
                continue

            cursor = conn.execute("""
                INSERT INTO ledger_entries (user_id, entry_type, amount, note, raw_transcript, confirmed, category)
                VALUES (?, ?, ?, ?, ?, 1, ?)
            """, (
                entry.user_id, entry.entry_type.value, entry.amount,
                entry.note, entry.raw_transcript, entry.category
            ))
            user_ids.add(entry.user_id)
            row = conn.execute(
                "SELECT * FROM ledger_entries WHERE id = ?", (cursor.lastrowid,)
            ).fetchone()
            results.append(_row_to_response(row))

    for uid in user_ids:
        compute_evidence_summary(uid)

    return results


def _row_to_response(row) -> LedgerEntryResponse:
    return LedgerEntryResponse(
        id=row["id"],
        user_id=row["user_id"],
        entry_type=row["entry_type"],
        amount=row["amount"],
        note=row["note"],
        raw_transcript=row["raw_transcript"],
        confirmed=bool(row["confirmed"]),
        category=row["category"],
        created_at=row["created_at"],
    )
