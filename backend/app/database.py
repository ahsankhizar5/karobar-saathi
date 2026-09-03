"""Karobar Saathi - Database configuration using SQLite."""
import os
import sqlite3
from contextlib import contextmanager

from app.config import settings

DB_PATH = os.path.join(os.path.abspath(settings.DATA_DIR), "karobar_saathi.db")


def get_connection():
    os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA journal_mode=WAL")
    conn.execute("PRAGMA foreign_keys=ON")
    return conn


@contextmanager
def get_db():
    conn = get_connection()
    try:
        yield conn
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()


def init_db():
    """Create all tables if they don't exist."""
    with get_db() as conn:
        conn.executescript("""
            CREATE TABLE IF NOT EXISTS users (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                business_type TEXT NOT NULL,
                business_name TEXT,
                phone TEXT,
                created_at TEXT NOT NULL DEFAULT (datetime('now')),
                updated_at TEXT NOT NULL DEFAULT (datetime('now'))
            );

            CREATE TABLE IF NOT EXISTS ledger_entries (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id TEXT NOT NULL,
                entry_type TEXT NOT NULL CHECK(entry_type IN ('sale', 'purchase', 'expense', 'withdrawal', 'unclear')),
                amount REAL NOT NULL,
                note TEXT,
                raw_transcript TEXT,
                confirmed INTEGER NOT NULL DEFAULT 0,
                category TEXT,
                created_at TEXT NOT NULL DEFAULT (datetime('now')),
                FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
            );

            CREATE TABLE IF NOT EXISTS evidence_summaries (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id TEXT NOT NULL UNIQUE,
                has_user_consented_to_share INTEGER NOT NULL DEFAULT 1,
                profile_generated_at TEXT NOT NULL DEFAULT (datetime('now')),
                avg_daily_sales REAL DEFAULT 0,
                avg_daily_expenses REAL DEFAULT 0,
                sales_volatility TEXT DEFAULT 'unknown',
                days_with_transactions INTEGER DEFAULT 0,
                cash_buffer_days INTEGER DEFAULT 0,
                net_cash_position REAL DEFAULT 0,
                total_sales_30d REAL DEFAULT 0,
                total_purchases_30d REAL DEFAULT 0,
                total_expenses_30d REAL DEFAULT 0,
                total_withdrawals_30d REAL DEFAULT 0,
                explainable_factors TEXT DEFAULT '[]',
                readiness_summary TEXT DEFAULT '',
                top_category TEXT DEFAULT '',
                top_category_margin REAL DEFAULT 0,
                killer_insight TEXT DEFAULT '',
                FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
            );

            CREATE INDEX IF NOT EXISTS idx_ledger_user_id ON ledger_entries(user_id);
            CREATE INDEX IF NOT EXISTS idx_ledger_created_at ON ledger_entries(created_at);
            CREATE INDEX IF NOT EXISTS idx_ledger_entry_type ON ledger_entries(entry_type);
        """)
