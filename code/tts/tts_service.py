from fastapi import FastAPI
from fastapi.responses import JSONResponse
from pydantic import BaseModel

import base64
import io
import math
import wave
from typing import Optional


class TtsRequest(BaseModel):
    text: str
    voice: Optional[str] = "default"


app = FastAPI()


def _generate_placeholder_wav(text: str, sample_rate: int = 16000, duration_sec: float = 1.0) -> bytes:
    """Generate a small placeholder WAV tone.

    This keeps the API contract working even before Kokoro is hooked up.
    """
    num_samples = int(sample_rate * duration_sec)
    amplitude = 0.3
    freq = 440.0  # A4 tone

    buffer = io.BytesIO()
    with wave.open(buffer, "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)  # 16-bit
        wf.setframerate(sample_rate)

        for n in range(num_samples):
            t = float(n) / sample_rate
            val = int(amplitude * 32767 * math.sin(2.0 * math.pi * freq * t))
            wf.writeframesraw(val.to_bytes(2, byteorder="little", signed=True))

    return buffer.getvalue()


@app.post("/tts")
async def tts_endpoint(req: TtsRequest):
    """Text-to-speech endpoint.

    For now, returns a small placeholder WAV tone encoded as base64.
    Once Kokoro is installed, replace the placeholder generator
    with a real Kokoro synthesis call that returns 16-bit PCM WAV.
    """
    wav_bytes = _generate_placeholder_wav(req.text)
    b64_audio = base64.b64encode(wav_bytes).decode("ascii")

    return JSONResponse({"audio": b64_audio, "sample_rate": 16000})


if __name__ == "__main__":
    import uvicorn

    uvicorn.run("code.tts.tts_service:app", host="0.0.0.0", port=8002, reload=True)
