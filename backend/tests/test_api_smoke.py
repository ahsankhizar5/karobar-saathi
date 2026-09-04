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


@pytest.mark.parametrize(
    "text, expected_type, expected_amount",
    [
        ("do hazar ki bikri hui", "sale", 2000.0),
        ("2 hazar ka maal khareeda", "purchase", 2000.0),
        ("paanch sau ka bijli ka bill diya", "expense", 500.0),
        ("saadhe teen hazar ki sale hui", "sale", 3500.0),
        ("dedh hazar ki kamai", "sale", 1500.0),
        ("dhai sau ka maal", "purchase", 250.0),
        ("3 hazar diye", "unclear", 3000.0),
        ("ek lakh ki bikri", "sale", 100000.0),
    ],
)
def test_rule_parser_understands_urdu_number_words(
    client, monkeypatch, text, expected_type, expected_amount
):
    from app.services import parsing

    monkeypatch.setattr(parsing.settings, "LLM_API_KEY", "")
    response = client.post(
        "/api/v1/voice/parse-text",
        json={"user_id": "shop_001", "text": text},
    )

    assert response.status_code == 200
    entries = response.json()["parsed_entries"]
    assert len(entries) == 1
    assert entries[0]["entry_type"] == expected_type
    assert entries[0]["amount"] == expected_amount


def test_rule_parser_does_not_read_kg_as_thousands(client, monkeypatch):
    from app.services import parsing

    monkeypatch.setattr(parsing.settings, "LLM_API_KEY", "")
    response = client.post(
        "/api/v1/voice/parse-text",
        json={"user_id": "shop_001", "text": "12 kg cheeni khareedi"},
    )

    assert response.status_code == 200
    entries = response.json()["parsed_entries"]
    assert all(entry["amount"] != 12000.0 for entry in entries)


@pytest.mark.parametrize("user_id", ["", "   "])
def test_parse_text_rejects_blank_user_id(client, user_id):
    response = client.post(
        "/api/v1/voice/parse-text",
        json={"user_id": user_id, "text": "Aaj 4500 ki sale hui."},
    )

    assert response.status_code == 422


@pytest.mark.parametrize("user_id", ["", "   "])
def test_transcribe_rejects_blank_user_id(client, user_id):
    response = client.post(
        "/api/v1/voice/transcribe",
        data={"user_id": user_id, "fallback_text": "Aaj 4500 ki sale hui."},
    )

    assert response.status_code == 422


def test_groq_transcription_sends_multipart_audio(monkeypatch, tmp_path):
    from app.services import transcription

    audio_file = tmp_path / "note.m4a"
    audio_file.write_bytes(b"fake-audio-bytes")

    class FakeResponse:
        def raise_for_status(self):
            return None

        def json(self):
            return {"text": "Aaj 4500 ki sale hui."}

    class FakeClient:
        request_url = None
        request_kwargs = None

        async def __aenter__(self):
            return self

        async def __aexit__(self, *args):
            return None

        async def post(self, url, **kwargs):
            FakeClient.request_url = url
            FakeClient.request_kwargs = kwargs
            return FakeResponse()

    fake_client = FakeClient()
    monkeypatch.setattr(transcription.settings, "TRANSCRIPTION_PROVIDER", "groq")
    monkeypatch.setattr(transcription.settings, "LLM_API_KEY", "test-key")
    monkeypatch.setattr(transcription.httpx, "AsyncClient", lambda *args, **kwargs: fake_client)

    transcript = asyncio.run(transcription.transcribe_audio_file(str(audio_file)))

    assert transcript == "Aaj 4500 ki sale hui."
    assert FakeClient.request_url == "https://api.groq.com/openai/v1/audio/transcriptions"
    assert FakeClient.request_kwargs["headers"]["Authorization"] == "Bearer test-key"
    file_name, file_obj, mime_type = FakeClient.request_kwargs["files"]["file"]
    assert file_name == "note.m4a"
    assert mime_type == "audio/mp4"
    assert FakeClient.request_kwargs["data"]["model"] == "whisper-large-v3"


def test_groq_transcription_skips_request_without_api_key(monkeypatch, tmp_path):
    from app.services import transcription

    monkeypatch.setattr(transcription.settings, "TRANSCRIPTION_PROVIDER", "groq")
    monkeypatch.setattr(transcription.settings, "LLM_API_KEY", "")

    audio_file = tmp_path / "note.wav"
    audio_file.write_bytes(b"fake-audio-bytes")

    def fail_post(*args, **kwargs):
        raise AssertionError("should not call the transcription API without a key")

    monkeypatch.setattr(
        transcription.httpx, "AsyncClient", lambda *args, **kwargs: type("NoClient", (), {"post": fail_post})()
    )

    transcript = asyncio.run(transcription.transcribe_with_fallback(str(audio_file), "typed fallback"))

    assert transcript == "typed fallback"


def test_transcribe_endpoint_uses_fallback_text_when_provider_disabled(client, monkeypatch, tmp_path):
    from app.services import parsing, transcription

    monkeypatch.setattr(transcription.settings, "TRANSCRIPTION_PROVIDER", "none")
    monkeypatch.setattr(parsing.settings, "LLM_API_KEY", "")

    audio_file = tmp_path / "note.m4a"
    audio_file.write_bytes(b"fake-audio-bytes")
    with open(audio_file, "rb") as audio:
        response = client.post(
            "/api/v1/voice/transcribe",
            files={"audio": ("note.m4a", audio, "audio/mp4")},
            data={"user_id": "shop_001", "fallback_text": "Aaj 4500 ki sale hui."},
        )

    assert response.status_code == 200
    body = response.json()
    assert body["raw_transcript"] == "Aaj 4500 ki sale hui."
    assert {(entry["entry_type"], entry["amount"]) for entry in body["parsed_entries"]} == {
        ("sale", 4500.0)
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


def test_evidence_returns_empty_profile_for_user_without_ledger_data(client):
    """A user row with no confirmed entries must not crash the endpoint."""
    from app.database import get_db

    with get_db() as connection:
        connection.execute(
            "INSERT INTO users (id, name, business_type) VALUES (?, ?, ?)",
            ("no_entries_user", "No Entries", "tea_stall"),
        )

    response = client.get(
        "/api/v1/evidence-profile/no_entries_user",
        headers={"X-User-Consent": "true"},
    )

    assert response.status_code == 200
    profile = response.json()
    assert profile["user_id"] == "no_entries_user"
    assert profile["metrics"]["days_with_transactions"] == 0
    assert profile["metrics"]["avg_daily_sales"] == 0


def test_evidence_returns_404_for_unknown_user(client):
    response = client.get(
        "/api/v1/evidence-profile/ghost_user",
        headers={"X-User-Consent": "true"},
    )

    assert response.status_code == 404


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
