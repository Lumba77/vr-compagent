# Local STT/TTS API Specification

This document defines minimal REST-style APIs for two local services:

- **STT service** using Faster-Whisper
- **TTS service** using Kokoro

These services are designed to integrate cleanly with the existing `/compagent` backend and Unity client.

---

## 1. STT Service (Faster-Whisper)

### Overview

- **Purpose**: Convert short audio clips (user speech) into text.
- **Technology**: Faster-Whisper (CTranslate2-based Whisper).
- **Suggested host/port**: `http://localhost:8001`

### Endpoint: `POST /stt`

- **URL**: `http://localhost:8001/stt`
- **Method**: `POST`
- **Content-Type**: `multipart/form-data`

#### Request Fields

- `audio` (required)
  - Type: file
  - Format: 16-bit mono PCM WAV (e.g. 16kHz or 24kHz)
- `language` (optional)
  - Type: string
  - Example: `"en"`, `"auto"`
  - Default: `"auto"`

#### Example Request (conceptual)

```http
POST /stt HTTP/1.1
Host: localhost:8001
Content-Type: multipart/form-data; boundary=---BOUNDARY

---BOUNDARY
Content-Disposition: form-data; name="audio"; filename="clip.wav"
Content-Type: audio/wav

<binary wav data>
---BOUNDARY--
```

#### Response

- **Content-Type**: `application/json`

```json
{
  "text": "I'm a bit overwhelmed by starting this VR AI project.",
  "language": "en"
}
```

- `text`: recognized transcript.
- `language`: detected or specified language code.

### Notes

- The STT service does **not** know about `/compagent`.
- Unity or another client is responsible for:
  - Recording audio from the microphone.
  - Encoding it as a WAV buffer.
  - Sending it to `/stt`.
  - Forwarding the resulting `text` to `/compagent` with `channel: "voice"`.

---

## 2. TTS Service (Kokoro)

### Overview

- **Purpose**: Convert response text from `/compagent` into audio for playback in Unity.
- **Technology**: Kokoro TTS.
- **Suggested host/port**: `http://localhost:8002`

### Endpoint: `POST /tts`

- **URL**: `http://localhost:8002/tts`
- **Method**: `POST`
- **Content-Type**: `application/json`

#### Request Body

```json
{
  "text": "That sounds like a big step. Let's break it down together.",
  "voice": "default"
}
```

- `text` (required): text to be spoken.
- `voice` (optional): identifier for a specific Kokoro voice.
  - Example: `"default"`, `"female_soft"`, `"male_calm"` (actual values depend on Kokoro setup).

#### Response (binary audio)

- **Option A (recommended)**: raw audio response
  - `Content-Type`: `audio/wav`
  - Body: binary WAV data (16-bit PCM mono).

**Unity usage**:
- Use `UnityWebRequestMultimedia.GetAudioClip` pattern or a custom WAV loader to:
  - Download the audio.
  - Construct an `AudioClip` at runtime.
  - Play via an `AudioSource` attached to the avatar.

#### Alternative Response (Base64 JSON)

If binary responses are inconvenient, an alternative format is:

```json
{
  "audio": "<base64-encoded-wav-or-ogg-data>",
  "sample_rate": 16000
}
```

Unity then decodes base64 to bytes and creates an `AudioClip` from the raw PCM.

### Notes

- The TTS service does **not** call `/compagent` directly.
- Unity or another orchestrator will:
  - Take `response` from `/compagent`.
  - Send it to `/tts`.
  - Play returned audio.

---

## 3. End-to-End Voice Flow

1. **User speaks**
   - Unity captures audio (e.g., push-to-talk or wake word triggered).

2. **STT**
   - Unity sends audio to `POST /stt`.
   - Receives `{ text, language }`.

3. **Compagent**
   - Unity sends:

     ```json
     {
       "input": "<transcript>",
       "channel": "voice"
     }
     ```

     to `POST /compagent`.

   - Receives `{ response, mode, channel }`.

4. **TTS**
   - Unity sends `{ text: response, voice: "default" }` to `POST /tts`.
   - Receives audio (WAV or base64).

5. **Playback**
   - Unity constructs an `AudioClip` and plays it via an `AudioSource` near the avatar.

This spec keeps STT, compagent logic, and TTS **cleanly separated**, while allowing you to run everything locally and swap out engines if desired.
