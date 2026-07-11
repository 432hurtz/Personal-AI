# The JI Project

**Joe** — a fully local, private research + coding assistant that **you** set
the rules for. Built to run on a modest Windows laptop.

- **Ollama** (native, CPU) runs Joe — nothing leaves your machine.
- **Open WebUI** is the chat face, bound to loopback only, telemetry off.
- **SearXNG** does web research; every query goes out over **Tor**.
- **You** own the guardrails — one editable file decides what's off limits.

"Joe" is the assistant (the model you talk to). "The JI Project" is the whole
stack around it. Built for: HP 14-fq0xxx, Athlon Silver 3050U, 18 GB RAM,
Windows 10. It's portable to anything better later.

## The four things you asked for, and where each lives

| Your goal | Where it's implemented | Strength |
|---|---|---|
| **You decide what's off limits** | `guardrails/system-prompt.txt` (you edit) | behavioral / soft |
| **Absolute privacy** | native Ollama + loopback + telemetry off (`docker-compose.yml`) | hard |
| **Research through Tor** | `searxng/settings.yml` (`socks5h://tor:9050`), incl. `.onion` via Ahmia + Torch; optional obfs4 **bridges** to hide Tor use from your ISP | hard |
| **Coding on this machine** | native Ollama at `localhost:11434` (`docs/CODING.md`) | — |
| **File & system control** | Open Interpreter agent — Joe shows a detailed plan (steps, sources, effect) and you approve everything before it acts (`docs/AGENT-CONTROL.md`) | your approval per action |

Read `guardrails/policy.md` — it explains that guardrails work in **3 layers**
(behavioral, network, filesystem) and which ones are hard vs. soft. That's the
honest core of "I decide what's off limits."

## Quick start (Windows)

Full walkthrough: **[docs/SETUP-WINDOWS.md](docs/SETUP-WINDOWS.md)**. Short form:

```powershell
# 1. Install Docker Desktop (WSL2 backend) and native Ollama.
# 2. Build your Joes (fast 'joe' + smart 'joe-7b') with guardrails + personality:
ollama pull nomic-embed-text          # local RAG embeddings
.\scripts\build-joes.ps1              # pulls the 3B + 7B and builds both

# 3. Put a real secret in searxng\settings.yml (secret_key line):
-join ((1..32) | ForEach-Object { '{0:x2}' -f (Get-Random -Max 256) })

# 4. Bring up the web/search/Tor side:
docker compose up -d
.\scripts\verify-tor.ps1        # expect IsTor:true

# 5. Open http://localhost:3000. Use the model dropdown (top-left of the chat)
#    to switch between "joe" (fast) and "joe-7b" (smart). Toggle the globe
#    icon to research over Tor.
```

## Docs

- **[docs/SETUP-WINDOWS.md](docs/SETUP-WINDOWS.md)** — step-by-step for your laptop
- **[guardrails/policy.md](guardrails/policy.md)** — how the guardrails actually enforce
- **[docs/PRIVACY.md](docs/PRIVACY.md)** — what "absolute privacy" does and doesn't mean, incl. what your ISP/websites can see
- **[docs/REMOTE-ACCESS.md](docs/REMOTE-ACCESS.md)** — SSH from your phone (LAN or Tailscale), no open ports
- **[docs/CODING.md](docs/CODING.md)** — connect VS Code / Aider to local Ollama; let Joe edit its own code
- **[docs/AGENT-CONTROL.md](docs/AGENT-CONTROL.md)** — give Joe permission-gated control of files + system
- **[docs/CONVERSATIONS.md](docs/CONVERSATIONS.md)** — organize, separate, delete, and truly purge chats + memory
- **[docs/HARDWARE.md](docs/HARDWARE.md)** — honest speed expectations + upgrade path

## Set your own rules — and Joe's personality

Two files, both yours, both baked into the model at build time:

- **`guardrails/system-prompt.txt`** — the hard RULES: `ALWAYS ALLOWED`,
  `ASK FIRST`, `OFF LIMITS`, plus privacy / plan-first / permission rules.
- **`guardrails/personality.txt`** — HOW Joe acts: tone, humor, verbosity,
  quirks. Personality colors delivery but can never override a rule. (Ships with
  a running "who is Joe → Joe Mama" bit as the first entry — edit or keep it.)

Edit either, then rerun `.\scripts\build-guarded-model.ps1` and restart the
chat. Rule changes prompt you to confirm (self-edit guard); personality tweaks
apply freely.

## Gotchas (the ones that bite everyone)

- [ ] JSON format enabled in `searxng/settings.yml`, or web search returns nothing.
- [ ] `socks5h`, not `socks5`, or you leak DNS.
- [ ] Open WebUI stays on `127.0.0.1` — the Ollama API has **no auth** at all.
- [ ] Raise SearXNG timeouts (done in the config) — Tor is slow.
- [ ] Keep search result count at 3 — RAG context is what OOMs a weak box.
- [ ] The original SearXNG GitHub repo was archived in mid-2026; use the Docker
      image (this repo does) and recent guides, not stale tutorials.

## Reality check

"Completely local" applies to the **model** — inference never leaves your
machine. Web research inherently touches the network; Tor hides *who* is asking,
not *that* someone asked. And a 3-4B model hallucinates — treat search results
as the source of truth and the model as a summarizer. See `docs/PRIVACY.md`.
