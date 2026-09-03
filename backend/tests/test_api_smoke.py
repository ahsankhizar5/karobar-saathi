import asyncio
import json
from datetime import datetime

import pytest
from fastapi.testclient import TestClient


@pytest.fixture
def client(tmp_path, monkeypatch):
    import app.database as database

    monkeypatch.setattr(database, "DB_PATH", str(tmp_path / "karobar_saathi.db"))

    from app.main import app

    with TestClient(app) as test_client:
        yield test_client


def test_health_is_healthy(client):
    response = client.get("/health")

    assert response.status_code == 200
    assert response.json() == {"status": "healthy"}


def test_parse_text_uses_roman_urdu_rules_without_llm(client, monkeypatch):
    from app.services import parsing

    monkeypatch.setattr(parsing.settings, "LLM_API_KEY", "")
    response = client.post(
        "/api/v1/voice/parse-text",
        json={
            "user_id": "shop_001",
            "text": "Aaj 4500 ki sale hui. 2000 ka maal khareeda. 800 ghar bheje.",
        },
    )

    assert response.status_code == 200
    entries = response.json()["parsed_entries"]
    assert {(entry["entry_type"], entry["amount"]) for entry in entries} == {
        ("sale", 4500.0),
        ("purchase", 2000.0),
        ("withdrawal", 800.0),
    }


def test_llm_parser_uses_structured_entries_response(monkeypatch):
    from app.services import parsing

    class FakeResponse:
        def raise_for_status(self):
            return None

        def json(self):
            return {
                "choices": [
                    {
                        "message": {
                            "content": json.dumps(
                                {
                                    "entries": [
                                        {
                                            "entry_type": "sale",
                                            "amount": 4500,
                                            "note": "Aaj ki bikri",
                                            "category": "other",
                                            "needs_clarification": False,
                                            "clarification_question": None,
                                        }
                                    ]
                                }
                            )
                        }
                    }
                ]
            }

    class FakeClient:
        request_json = None

        async def __aenter__(self):
            return self

        async def __aexit__(self, *args):
            return None

        async def post(self, *args, **kwargs):
            self.request_json = kwargs["json"]
            return FakeResponse()

    fake_client = FakeClient()
    monkeypatch.setattr(parsing.settings, "LLM_API_KEY", "test-key")
    monkeypatch.setattr(parsing.httpx, "AsyncClient", lambda *args, **kwargs: fake_client)

    entries = asyncio.run(parsing.parse_with_llm("Aaj pentaalis sau ki bikri hui."))

    assert entries[0].entry_type.value == "sale"
    assert entries[0].amount == 4500.0
    assert fake_client.request_json["response_format"]["type"] == "json_schema"
    assert fake_client.request_json["response_format"]["json_schema"]["strict"] is True


def test_dashboard_calculates_confirmed_entries(client):
    from app.database import get_db

    created_at = datetime.utcnow().isoformat()
    with get_db() as connection:
        connection.execute(
            "INSERT INTO users (id, name, business_type) VALUES (?, ?, ?)",
            ("dashboard_test", "Dashboard Test", "tea_stall"),
        )
        connection.executemany(
            """
            INSERT INTO ledger_entries
                (user_id, entry_type, amount, note, raw_transcript, confirmed, category, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            """,
            [
                ("dashboard_test", "sale", 1500, "Sale", "1500 sale", 1, "tea", created_at),
                ("dashboard_test", "purchase", 400, "Stock", "400 stock", 1, "tea", created_at),
                ("dashboard_test", "expense", 200, "Bill", "200 bill", 1, "utilities", created_at),
            ],
        )

    response = client.get("/api/v1/dashboard/dashboard_test")

    assert response.status_code == 200
    dashboard = response.json()
    assert dashboard["today_sales"] == 1500.0
    assert dashboard["today_expenses"] == 600.0
    assert dashboard["today_profit"] == 900.0
    assert dashboard["cash_position"] == 900.0
    assert len(dashboard["weekly_trend"]) == 7


def test_evidence_requires_active_consent_and_header(client):
    denied = client.get("/api/v1/evidence-profile/shop_001")
    allowed = client.get(
        "/api/v1/evidence-profile/shop_001",
        headers={"X-User-Consent": "true"},
    )
    revoked = client.patch(
        "/api/v1/evidence-profile/shop_001/consent",
        json={"has_user_consented_to_share": False},
    )
    denied_after_revoke = client.get(
        "/api/v1/evidence-profile/shop_001",
        headers={"X-User-Consent": "true"},
    )

    assert denied.status_code == 403
    assert denied.json()["detail"]["error"] == "consent_required"
    assert allowed.status_code == 200
    assert allowed.json()["has_user_consented_to_share"] is True
    assert revoked.status_code == 200
    assert denied_after_revoke.status_code == 403
    assert denied_after_revoke.json()["detail"]["has_user_consented_to_share"] is False
