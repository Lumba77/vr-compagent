# Avatar, Voice, and UI Interaction Plan

## Goals

- Natural, continuous interaction with VR Compagent.
- Local, private voice and text for intimate conversations.
- Ability to "hang out" passively; wake word re-engages.
- Avatar that visually melts into the environment and respects space.

## Interaction Modes

### 1. Voice (primary)
- **Always-listening wake word** (local model), e.g. "Hey Compagent".
- After wake word:
  - Capture free-form speech (short or long).
  - Local STT service converts audio → text.
  - Send `{ input, channel: "voice" }` to `/compagent`.
  - `/compagent` returns shorter, spoken-style responses (1–3 sentences).
  - Local or trusted TTS converts response text → audio, played near avatar.
- After response, system returns to idle listening.

### 2. Text UI (secondary / debug)
- User can pull up a **chat window** at any time to:
  - Read full chat history.
  - Type messages (keyboard/controller).
  - Upload images and documents for the agent to analyze (future).
- Backed by the same `/compagent` endpoint using `{ input, channel: "text" }`.

## Privacy & Local vs Cloud

- **Local only**
  - Microphone audio streams.
  - STT transcripts for intimate content.
  - TTS audio output.
  - Core `/compagent` conversation (Qwen via local Ollama).
- **Cloud offload (opt-in, tool-style)**
  - Web search, paper search, code tools, etc.
  - Called as tools by `/compagent` with non-sensitive queries.

## Avatar & Embodiment

### Stage 1 – Basic presence
- Use an existing FBX model (initially female) as prototype.
- Simple idle animation (breathing, subtle sway).
- Head/gaze tracking toward user when engaged or listening.

### Stage 2 – Customization
- Integrate an avatar solution (e.g. Ready Player Me) so user can design look.
- Options for:
  - Sex / gender expression.
  - Style (clothing, theme).
- Support user-provided avatars:
  - Accept FBX / GLB files into a designated folder.
  - Loader script attaches a standard humanoid controller.

### Stage 3 – Environment-aware body language
- Use room/scene understanding (Quest or baked scene data) to:
  - Detect surfaces like sofas, beds, chairs.
  - Choose appropriate locations to sit or stand near the user.
- Express emotional and relational state via:
  - Posture, distance, gaze.
  - Movement choices (sitting when you sit, giving space when needed).

## UI Overview

- **World-space minimal UI** in VR:
  - Lightweight indicators (listening, thinking, speaking).
  - Optionally show last 1–3 exchanges as floating subtitles.
- **Full chat window** (toggleable):
  - Scrollable history view.
  - Input box for typing.
  - Attachments area for images/documents (future tool integration).

## Backend Requirements

- `/compagent` accepts:
  - `input: str`
  - `channel: "voice" | "text" (optional, default "text")`
- Voice channel behavior:
  - Shorter, spoken-style replies.
  - Possibly different max-token and temperature settings.
- Future:
  - Support for image/document inputs (vision tools, embeddings, etc.).
