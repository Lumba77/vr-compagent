# VR-compagent — Project Brief (load this first)

## One-sentence goal

A Quest/OpenXR Unity VR app that presents a world-space UI panel and acts as a “companion + agent”, sending text/voice to local backend services (LLM/STT/TTS) and showing responses in VR.

## Target runtime

- PCVR app (run on Windows PC) using OpenXR.
- Primary headset during development: Meta Quest via Link/AirLink.
- Goal: stay as headset-agnostic as possible via OpenXR.
- Backend runs on the same PC (local network/loopback), e.g. Docker + Ollama.

## Product stance (privacy-first)

- Primary mode is local/private operation (no mandatory third-party cloud).
- PCVR + local PC backend is the baseline that must work.
- Quest standalone mode is optional and may be:
  - limited (smaller on-device models), or
  - connected to a user-owned/self-hosted backend (LAN/Wi-Fi).

## Current objective (what we’re actively fixing)

- Make the world-space UI reliably:
  - Visible on Quest
  - Properly framed with a blue background + margins
  - Clickable/typable in VR (XR UI input + controller rays aligned)
- Reduce only *blocking* errors first; ignore noisy warnings unless they break input/rendering.

## Architecture (high level)

- **Unity scene (authoritative):** `code/unity/VR-compagent/Assets/VR_compagent.unity`
- **XR stack:** XR Interaction Toolkit + OpenXR + Meta XR packages
- **UI:** World-space Canvas (layer 3) parented under XR rig camera offset.
- **Backend endpoints (used by Unity):**
  - `http://localhost:8000/compagent`
  - `http://localhost:8001/stt`
  - `http://localhost:8002/tts`

## Key Unity objects / invariants

- `Canvas (1)` is a **world-space** Canvas and must stay on **layer 3**.
- `Main Camera` must **render layer 3** (culling mask must include UI layer).
- UI elements live under `ui root`.

## Recent fixes (so we don’t re-suggest them)

- Fixed scene YAML corruption (duplicate fileIDs / broken PPtr child).
- Fixed UI invisibility by restoring `Main Camera` culling mask to include UI layer.
- Fixed missing UI elements by de-overlapping RectTransforms (elements were stacked at nearly the same anchored position).

## Known noisy warnings (usually not the root cause)

- `MRUK Shared: Unable to bind OpenXR function` (often spammy; only act if it blocks XR/UI input).
- `Call to StopSubsystems without an initialized manager` (often during editor reloads; usually non-fatal).

## How to use this file in new AI sessions

Paste this at the start of a new session:

"Read `PROJECT_BRIEF.md` and then help me with: [your task]. If you propose changes, reference the authoritative files and avoid undoing the recent fixes listed in the brief."

## Working style constraints (to prevent regressions)

- Prefer small, reversible diffs.
- Avoid deleting assets.
- If touching `VR_compagent.unity`, be careful with fileID references.
