"""Voice router — handles audio upload + text transcript, returns parsed entries."""
import os
import uuid
from fastapi import APIRouter, UploadFile, File, Form, HTTPException
from app.services.transcription import transcribe_with_fallback
from app.services.parsing import parse_with_llm
from app.models.schemas import TranscriptResponse, TranscriptRequest
from app.config import settings

router = APIRouter(prefix="/api/v1/voice", tags=["voice"])


@router.post("/transcribe", response_model=TranscriptResponse)
async def transcribe_and_parse(
    audio: UploadFile = File(None),
    user_id: str = Form(...),
    fallback_text: str = Form(None),
):
    """Upload an audio file for transcription, or provide text directly."""
    transcript = ""

    if audio and audio.filename:
        os.makedirs(settings.UPLOAD_DIR, exist_ok=True)
        ext = os.path.splitext(audio.filename)[1] or ".m4a"
        filename = f"{uuid.uuid4()}{ext}"
        filepath = os.path.join(settings.UPLOAD_DIR, filename)

        content = await audio.read()
        with open(filepath, "wb") as f:
            f.write(content)

        transcript = transcribe_with_fallback(filepath, fallback_text)

        if os.path.exists(filepath):
            os.remove(filepath)

    elif fallback_text:
        transcript = fallback_text

    if not transcript or not transcript.strip():
        raise HTTPException(
            status_code=422,
            detail="Could not transcribe audio and no fallback text provided. Try typing your transaction instead."
        )

    parsed_entries = await parse_with_llm(transcript)

    return TranscriptResponse(
        parsed_entries=parsed_entries,
        raw_transcript=transcript,
    )


@router.post("/parse-text", response_model=TranscriptResponse)
async def parse_text_input(request: TranscriptRequest):
    """Parse a text input directly (manual text entry fallback)."""
    if not request.text or not request.text.strip():
        raise HTTPException(status_code=422, detail="Text cannot be empty")

    parsed_entries = await parse_with_llm(request.text)

    return TranscriptResponse(
        parsed_entries=parsed_entries,
        raw_transcript=request.text,
    )
