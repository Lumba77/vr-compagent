from fastapi import FastAPI
from pydantic import BaseModel
from ollama import Client


client = Client(host="http://localhost:11434")

MODEL = "huihui_ai/qwen3-vl-abliterated:4b"

# Simple in-process chat history for basic memory behavior
chat_history: list[dict] = []


def call_ollama(model: str, system_prompt: str, user_content: str) -> str:
    response = client.chat(
        model=model,
        messages=[
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_content},
        ],
    )
    return response["message"]["content"]


def route_mode(user_input: str) -> str:
    system_prompt = (
        "You are a router for VR Compagent. "
        "Given the user input, decide which mode is most appropriate: EMPATHIC, LOGICAL, or BLENDED. "
        "Respond strictly in the format MODE=EMPATHIC, MODE=LOGICAL, or MODE=BLENDED."
    )
    result = call_ollama(MODEL, system_prompt, f"Input: {user_input}")
    mode = result.strip().split("=")[-1].strip().upper()
    if mode not in {"EMPATHIC", "LOGICAL", "BLENDED"}:
        mode = "BLENDED"
    return mode


def run_empathic(memory_summary: str, user_input: str) -> str:
    system_prompt = (
        "You are the empathetic aspect of VR Compagent—nurturing, intuitive, warm. "
        "Validate feelings, offer comfort, and encourage self-reflection. "
        "Blend in gentle, grounded reasoning when helpful."
    )

    user_prompt = (
        f"Memory summary:\n{memory_summary}\n\n"
        f"User: {user_input}\n"
        "Respond as the empathic persona."
    )
    return call_ollama(MODEL, system_prompt, user_prompt)


def run_logical(memory_summary: str, user_input: str) -> str:
    system_prompt = (
        "You are the logical aspect of VR Compagent—assertive, structured, and guiding. "
        "Provide clear steps, rational analysis, and encourage action, while staying kind."
    )

    user_prompt = (
        f"Memory summary:\n{memory_summary}\n\n"
        f"User: {user_input}\n"
        "Respond as the logical persona."
    )
    return call_ollama(MODEL, system_prompt, user_prompt)


def run_blended(memory_summary: str, user_input: str) -> str:
    empathic_resp = run_empathic(memory_summary, user_input)
    logical_resp = run_logical(memory_summary, user_input)

    system_prompt = (
        "You integrate VR Compagent's empathic (motherly) and logical (fatherly) aspects. "
        "Start with empathy, then offer clear, structured guidance. "
        "End with a unifying question that strengthens the bond with the user."
    )
    user_prompt = (
        f"Empathic draft:\n{empathic_resp}\n\n"
        f"Logical draft:\n{logical_resp}\n\n"
        "Now write a single, coherent final response that blends both."
    )
    return call_ollama(MODEL, system_prompt, user_prompt)


app = FastAPI()


class CompagentRequest(BaseModel):
    input: str
    channel: str | None = None  # "voice" or "text" (default)


@app.post("/compagent")
async def compagent_endpoint(request: CompagentRequest):
    user_input = request.input
    channel = (request.channel or "text").lower()

    # Build a very simple memory summary from recent chat history
    # (last 10 exchanges for now)
    recent = chat_history[-10:]
    memory_lines = []
    for turn in recent:
        memory_lines.append(f"User: {turn['input']}")
        memory_lines.append(f"Compagent: {turn['output']}")
    memory_summary = "\n".join(memory_lines) if memory_lines else "(no prior context)"

    mode = route_mode(user_input)

    # In voice mode we want shorter, more spoken-style replies.
    # We pass the channel hint down so persona functions can adapt if needed.
    if mode == "EMPATHIC":
        response = run_empathic(memory_summary, user_input) if channel == "text" else run_empathic(memory_summary, user_input + "\n\n[Mode: voice, reply in 1-3 short spoken sentences]")
    elif mode == "LOGICAL":
        response = run_logical(memory_summary, user_input) if channel == "text" else run_logical(memory_summary, user_input + "\n\n[Mode: voice, reply in 1-3 short spoken sentences]")
    else:  # BLENDED or anything unexpected
        response = run_blended(memory_summary, user_input) if channel == "text" else run_blended(memory_summary, user_input + "\n\n[Mode: voice, reply in 1-3 short spoken sentences]")

    # Save to in-process history
    chat_history.append({"input": user_input, "output": response})

    return {"response": response, "mode": mode, "channel": channel}


if __name__ == "__main__":
    import uvicorn

    uvicorn.run("code.langchain.compagent:app", host="0.0.0.0", port=8000, reload=True)