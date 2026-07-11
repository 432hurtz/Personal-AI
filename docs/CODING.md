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

## Working on Joe's own code

Joe can edit **its own** project too — just point the tool at the JI folder:

```powershell
cd C:\JI                      # the JI Project itself
aider --model ollama/joe      # Joe can now read + edit its own files
```

It can rewrite anything here, including `guardrails/system-prompt.txt` — its own
rules. There's an important safety property built in:

- **Editing the rules file does nothing to the running Joe until you rebuild.**
  `guardrails/system-prompt.txt` only takes effect when you run
  `scripts\build-guarded-model.ps1` and reselect the model. So Joe can *propose*
  changes to its own guardrails, but it can't make them live — that's your step.
- **The build script now flags self-edits.** If the guardrails changed since the
  last build, the script stops and makes you confirm before rebuilding (it
  compares a hash stored in `guardrails/.last-build-hash`). A quietly loosened
  rule can't slip into a rebuild unreviewed. Use `-Force` to skip the prompt
  only when you know what changed.

If you want Joe to not just edit code but also run commands / manage files on the
machine, see **[AGENT-CONTROL.md](AGENT-CONTROL.md)** — that's the
permission-gated system-control setup.
