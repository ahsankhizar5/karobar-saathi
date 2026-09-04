from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime
from enum import Enum


class EntryType(str, Enum):
    SALE = "sale"
    PURCHASE = "purchase"
    EXPENSE = "expense"
    WITHDRAWAL = "withdrawal"
    UNCLEAR = "unclear"


class UserCreate(BaseModel):
    id: str
    name: str
    business_type: str
    business_name: Optional[str] = None
    phone: Optional[str] = None


class UserResponse(BaseModel):
    id: str
    name: str
    business_type: str
    business_name: Optional[str] = None
    phone: Optional[str] = None
    created_at: str


class LedgerEntryCreate(BaseModel):
    user_id: str
    entry_type: EntryType
    amount: float
    note: Optional[str] = None
    raw_transcript: Optional[str] = None
    category: Optional[str] = None
    confirmed: bool = False


class LedgerEntryResponse(BaseModel):
    id: int
    user_id: str
    entry_type: str
    amount: float
    note: Optional[str] = None
    raw_transcript: Optional[str] = None
    confirmed: bool
    category: Optional[str] = None
    created_at: str


class LedgerEntryConfirm(BaseModel):
    entry_type: Optional[EntryType] = None
    amount: Optional[float] = None
    note: Optional[str] = None
    category: Optional[str] = None


class ParsedEntry(BaseModel):
    entry_type: EntryType
    amount: float
    note: Optional[str] = None
    category: Optional[str] = None
    needs_clarification: bool = False
    clarification_question: Optional[str] = None


class TranscriptRequest(BaseModel):
    user_id: str = Field(min_length=1, pattern=r"\S")
    text: str


class TranscriptResponse(BaseModel):
    parsed_entries: list[ParsedEntry]
    raw_transcript: str


class DashboardResponse(BaseModel):
    today_profit: float
    today_sales: float
    today_expenses: float
    weekly_trend: list[dict]
    cash_position: float
    top_category: Optional[str] = None
    top_category_margin: Optional[float] = None
    killer_insight: str
    total_entries_today: int


class MetricsModel(BaseModel):
    avg_daily_sales: float
    sales_volatility: str
    days_with_transactions: int
    cash_buffer_days: int


class EvidenceProfileResponse(BaseModel):
    user_id: str
    has_user_consented_to_share: bool
    profile_generated_at: str
    metrics: MetricsModel
    explainable_factors: list[str]
    readiness_summary: str


class ConsentUpdate(BaseModel):
    has_user_consented_to_share: bool
