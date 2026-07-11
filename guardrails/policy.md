# Guardrails — how "you decide what's off limits" actually works

You wanted to be the one who sets the boundaries. Here's the honest picture of
how that gets enforced, because it happens at **three different layers** and
they are not equally strong.

## Layer 1 — Behavioral (the system prompt)  ← the one you edit most

`system-prompt.txt` is baked into your model with `ollama create` (see
`scripts/build-guarded-model.ps1`). It tells the model what you allow, what to
ask about, and what's off limits.

**Strength: soft.** This is instruction-following, not a sandbox. Because the
model is *yours* and runs locally, there is no external policy layer fighting
you — but also nothing stopping a cleverly worded prompt from talking the model
past its own rules. That's fine: you own both sides. Treat this layer as
"define the assistant's default behavior," not "unbreakable jail."

To change it: edit `system-prompt.txt`, rerun the build script, restart.

## Layer 2 — Network (Tor + loopback)  ← hard boundary

- SearXNG's outbound traffic is *forced* through Tor (`socks5h://tor:9050`).
  There is no non-Tor egress path configured for search.
- Open WebUI is bound to `127.0.0.1` only — not reachable from your LAN.
- Open WebUI telemetry is disabled (`ANONYMIZED_TELEMETRY=false`,
  `DO_NOT_TRACK=true`, `SCARF_NO_ANALYTICS=true`), and external model providers
  are turned off (`ENABLE_OPENAI_API=false`).

**Strength: hard.** This is config, not vibes. The model can't reach the
internet except through the search path you built.

## Layer 3 — Filesystem (scope of the coding tool)  ← hard boundary

The model only "has hands" when you connect a coding tool (Continue.dev, Aider)
to it. That tool decides which files the model can read/write — **not the
system prompt.** So the real filesystem guardrail is: *point the tool at one
project folder at a time.* See `docs/CODING.md`. Aider, for example, only edits
files in the repo you launched it in and shows you a diff before applying.

## The short version

| You want to forbid...        | Enforce it at...                    | How hard |
|------------------------------|-------------------------------------|----------|
| A topic / behavior           | Layer 1: `system-prompt.txt`        | soft     |
| Data leaving the machine     | Layer 2: already done (Tor+loopback)| hard     |
| Touching the wrong files     | Layer 3: scope the editor/Aider     | hard     |

Edit Layer 1 freely — that's the "OFF LIMITS" block in `system-prompt.txt`.
Leave it empty for an unrestricted assistant, or fill it in. Your call.
