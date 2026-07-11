# Coding — connect your editor to local Ollama

Ollama exposes an OpenAI-compatible API at `http://localhost:11434/v1`. Because
Ollama runs **natively** on your laptop, editor tools reach it directly at
`localhost` — no Docker networking involved. This is also where the filesystem
guardrail lives (Layer 3 in `guardrails/policy.md`): **the tool decides which
files the model can touch, so scope it to one project at a time.**

## Option A — Continue.dev (VS Code / JetBrains)

Best for inline chat + autocomplete inside the editor.

1. Install the **Continue** extension.
2. Open its config (`~/.continue/config.json` on Windows:
   `C:\Users\<you>\.continue\config.json`) and set:

```json
{
  "models": [
    {
      "title": "joe (guarded)",
      "provider": "ollama",
      "model": "joe"
    },
    {
      "title": "qwen coder 3b",
      "provider": "ollama",
      "model": "qwen2.5-coder:3b"
    }
  ],
  "tabAutocompleteModel": {
    "title": "autocomplete",
    "provider": "ollama",
    "model": "qwen2.5-coder:1.5b"
  }
}
```

Use a *tiny* model (`qwen2.5-coder:1.5b`) for autocomplete so completions stay
snappy while the bigger model handles chat. On your CPU, don't run autocomplete
and a 7B chat at the same time — they'll fight for the 2 threads.

```powershell
ollama pull qwen2.5-coder:1.5b
```

## Option B — Aider (terminal, edits real files with diffs)

Best when you want the model to actually make multi-file changes. Aider only
touches files in the repo you launch it in and shows a diff before applying —
that's your filesystem guardrail.

```powershell
pip install aider-install; aider-install     # or: pipx install aider-chat
cd C:\path\to\your\project                    # scope = this folder only
aider --model ollama/joe
```

Point `--model` at your guarded model to carry your system-prompt rules into
coding sessions, or at `ollama/qwen2.5-coder:7b` for raw capability.

## Option C — anything that speaks OpenAI

Point it at the Ollama OpenAI shim; any dummy key works:

```powershell
$env:OPENAI_BASE_URL = "http://localhost:11434/v1"
$env:OPENAI_API_KEY  = "ollama"
```

## Guardrails while coding

- Your `system-prompt.txt` rules ride along **only if you use the `joe`
  model.** If you point a tool at a raw base model, you get no behavioral rules.
- The hard filesystem boundary is the tool's scope, not the prompt. Launch
  Aider / open the editor in exactly the folder you want reachable.
- Keep destructive git operations behind the "ASK FIRST" rule — Aider won't
  push for you, but you can wire commits carefully.
