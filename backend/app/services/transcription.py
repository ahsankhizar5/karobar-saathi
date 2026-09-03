"""Voice transcription service using faster-whisper with fallback to direct text."""
from typing import Optional

from app.config import settings


def transcribe_audio_file(audio_path: str) -> str:
    """Transcribe an audio file when Whisper is enabled."""
    if not settings.WHISPER_ENABLED:
        return ""

    try:
        from faster_whisper import WhisperModel
        model_size = settings.WHISPER_MODEL
        model = WhisperModel(model_size, device="cpu", compute_type="int8")
        segments, info = model.transcribe(audio_path, language=None, beam_size=5)
        transcript = " ".join(segment.text for segment in segments)
        return transcript.strip()
    except ImportError:
        return ""
    except Exception as e:
        print(f"[Transcription Error] {e}")
        return ""


def transcribe_with_fallback(audio_path: str, fallback_text: Optional[str] = None) -> str:
    """Try Whisper first, fall back to provided text."""
    result = transcribe_audio_file(audio_path)
    if result:
        return result
    if fallback_text:
        return fallback_text
    return ""
