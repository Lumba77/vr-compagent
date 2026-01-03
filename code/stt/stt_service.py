

> big-agi@2.0.1 dev
> next dev --turbopack

 🧠 big-AGI v2.0.1 (@8a570e912)
 ⚠ Port 3000 is in use by process 21296, using available port 3001 instead.
 🧠 big-AGI v2.0.1 (@8a570e912)
   ▲ Next.js 15.5.7 (Turbopack)
   - Local:        http://localhost:3001
   - Network:      http://192.168.8.100:3001

 ✓ Starting...
 ✓ Ready in 1558ms
 ⚠ Webpack is configured while Turbopack is not, which may cause problems.
 ⚠ See instructions if you need to configure Turbopack:
  https://nextjs.org/docs/app/api-reference/next-config-js/turbopack


from fastapi import FastAPI, File, Form, UploadFile
from fastapi.responses import JSONResponse
from faster_whisper import WhisperModel

import os
import tempfile
from typing import Optional


# Configure model
# You can change "small" to "base", "medium", etc. depending on speed/quality trade-offs.
MODEL_SIZE = "tiny"
DEVICE = "cuda"  # "cuda" | "cpu" | "auto"


app = FastAPI()


# Load model once at startup
model: WhisperModel = WhisperModel(MODEL_SIZE, device=DEVICE)


@app.post("/stt")
async def transcribe_audio(
    audio: UploadFile = File(...),
    language: Optional[str] = Form("auto"),
):
    """Speech-to-text endpoint using Faster-Whisper.

    Expects multipart/form-data with an 'audio' file field (WAV) and optional 'language'.
    Returns JSON: {"text": ..., "language": ...}.
    """

    # Save uploaded file to a temporary path so Faster-Whisper can read it
    try:
        suffix = os.path.splitext(audio.filename or "audio.wav")[1] or ".wav"
    except Exception:
        suffix = ".wav"

    with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as tmp:
        tmp_path = tmp.name
        content = await audio.read()
        tmp.write(content)
        tmp.flush()

    try:
        # language=None lets the model auto-detect
        lang_arg = None if language in (None, "", "auto") else language

        segments, info = model.transcribe(tmp_path, language=lang_arg)

        # Concatenate segments into a single string
        text_parts = [segment.text.strip() for segment in segments]
        full_text = " ".join(t for t in text_parts if t)

        detected_lang = info.language if hasattr(info, "language") else (language or "auto")

        return JSONResponse({"text": full_text, "language": detected_lang})

    finally:
        try:
            os.remove(tmp_path)
        except OSError:
            pass


if __name__ == "__main__":
    import uvicorn

    uvicorn.run("code.stt.stt_service:app", host="0.0.0.0", port=8001, reload=True)
