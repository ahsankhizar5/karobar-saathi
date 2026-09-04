"""Voice transcription — hosted Groq Whisper API by default, local faster-whisper as an option."""
import os
from typing import Optional

import httpx

from app.config import settings


_MIME_TYPES = {
    ".m4a": "audio/mp4",
    ".mp3": "audio/mpeg",
    ".mp4": "audio/mp4",
    ".mpeg": "audio/mpeg",
    ".mpga": "audio/mpeg",
    ".wav": "audio/wav",
    ".webm": "audio/webm",
}


async def transcribe_audio_file(audio_path: str) -> str:
    """Transcribe an audio file using the configured provider."""
    provider = settings.TRANSCRIPTION_PROVIDER.strip().lower()

    if provider == "groq":
        if not settings.LLM_API_KEY:
            return ""
        return await _transcribe_with_groq(audio_path)
    if provider == "local":
        return _transcribe_with_local_whisper(audio_path)
    return ""


async def _transcribe_with_groq(audio_path: str) -> str:
    filename = os.path.basename(audio_path)
    mime_type = _MIME_TYPES.get(os.path.splitext(filename)[1].lower(), "application/octet-stream")

    try:
        async with httpx.AsyncClient(timeout=60.0) as client:
            with open(audio_path, "rb") as audio_file:
                response = await client.post(
                    settings.GROQ_TRANSCRIBE_URL,
                    headers={"Authorization": f"Bearer {settings.LLM_API_KEY}"},
                    files={"file": (filename, audio_file, mime_type)},
                    data={
                        "model": settings.GROQ_TRANSCRIBE_MODEL,
                        "response_format": "json",
                    },
                )
            response.raise_for_status()
            return (response.json().get("text") or "").strip()
    except Exception as e:
        print(f"[Groq Transcription Error] {e}")
        return ""


def _transcribe_with_local_whisper(audio_path: str) -> str:
    try:
        from faster_whisper import WhisperModel

        model = WhisperModel(settings.WHISPER_MODEL, device="cpu", compute_type="int8")
        segments, info = model.transcribe(audio_path, language=None, beam_size=5)
        return " ".join(segment.text for segment in segments).strip()
    except ImportError:
        return ""
    except Exception as e:
        print(f"[Transcription Error] {e}")
        return ""


async def transcribe_with_fallback(audio_path: str, fallback_text: Optional[str] = None) -> str:
    """Try the configured transcription provider first, fall back to provided text."""
    result = await transcribe_audio_file(audio_path)
    if result:
        return result
    if fallback_text:
        return fallback_text
    return ""
