# The JI Project — Setup on Windows 10 (your HP 14-fq0xxx)

This is written for **your** machine: Windows 10 Pro, AMD Athlon Silver 3050U
(2 cores / 2 threads), 18 GB RAM, integrated Radeon 2 GB, ~779 GB free.

The architecture on your laptop:

```
   VS Code / Aider ──► Ollama (native Windows, CPU)  :11434
                                  ▲
                                  │ host.docker.internal
   ┌──────────────── Docker Desktop ────────────────┐
   │  Open WebUI :3000 (loopback) ──► SearXNG ──► Tor │
   └──────────────────────────────────────────────────┘
                                          │
                                          ▼  (Tor)
                                     the internet
```

Ollama runs **natively** (not in Docker) so it's as fast as your CPU allows and
so your editor can talk to it at `localhost:11434`. Everything else is in
Docker.

---

## Step 0 — A blunt word on speed

Your GPU can't help here. Ollama does not accelerate on the Athlon's Vega
iGPU, so this is **CPU-only** on 2 threads. Your 18 GB of RAM is plenty; the
CPU is the ceiling. Realistic expectations:

| Model                     | Size | Realistic speed on your CPU | Use for            |
|---------------------------|------|-----------------------------|--------------------|
| `qwen2.5-coder:3b`        | 3B   | ~5-9 tok/s                  | daily coding driver|
| `phi4-mini` / `gemma3:4b` | ~4B  | ~4-7 tok/s                  | daily chat/research|
| `qwen2.5-coder:7b`        | 7B   | ~2-4 tok/s (usable, slow)   | "worth the wait"   |
| `llama3.1:8b`             | 8B   | ~2-3 tok/s                  | general, patient   |

**Recommendation:** make a **3-4B model your daily driver**, and keep a 7B
around for hard problems you're willing to wait on. RAM lets you *load* an 8B;
the CPU is what makes it slow. Keep `num_ctx` at 4096.

---

## Step 1 — Install Docker Desktop (with WSL2)

1. Install **WSL2** (PowerShell as admin): `wsl --install` then reboot.
2. Install **Docker Desktop for Windows**, choose the **WSL2 backend** during
   setup. Launch it once and let it finish starting.

## Step 2 — Install Ollama natively

1. Download the Windows installer from `https://ollama.com/download` and run it.
2. Confirm it's up (new PowerShell window):
   ```powershell
   ollama --version
   ```
   Ollama runs as a background service on `127.0.0.1:11434`.

## Step 3 — Pull models and build your Joes

```powershell
cd <path-to>\personal-ai

# Local embeddings for web-search RAG -- keeps everything offline (small, fast)
ollama pull nomic-embed-text

# Build BOTH Joes (fast + smart) with your guardrails + personality.
# This pulls qwen2.5-coder:3b and :7b for you.
.\scripts\build-joes.ps1
```

This creates two models you can switch between (Step 6):

- **`joe`** — fast daily driver (3B), ~5-9 tok/s on your CPU.
- **`joe-7b`** — smarter but slower (7B), ~2-4 tok/s.

Prefer just one? Run `.\scripts\build-guarded-model.ps1` on its own — it builds
`joe` from the 3B by default.

Edit `guardrails\system-prompt.txt` (the rules) or `guardrails\personality.txt`
(how Joe talks/acts) any time and rerun the build to apply the changes. See
`guardrails\policy.md` for how the guardrails actually work.

## Step 4 — Set the SearXNG secret

Generate a secret and paste it into `searxng\settings.yml` (the `secret_key:`
line):

```powershell
-join ((1..32) | ForEach-Object { '{0:x2}' -f (Get-Random -Max 256) })
```

## Step 5 — Bring up the stack

```powershell
docker compose up -d
docker compose logs -f        # watch it start; Ctrl+C to stop watching
```

Give Tor a minute to bootstrap, then verify egress really goes through Tor:

```powershell
.\scripts\verify-tor.ps1       # expect: IsTor:true
```

## Step 6 — Wire up Open WebUI

1. Open `http://localhost:3000`, create the **local** admin account (it never
   leaves your machine, but still use a real password).
2. **Admin Panel -> Settings -> Connections**: Ollama Base URL should already be
   `http://host.docker.internal:11434`. If a manual box is shown, use that value
   (NOT `localhost` — you're inside the Docker network).
3. **Admin Panel -> Settings -> Web Search**: enable, engine = `searxng`,
   Query URL = `http://searxng:8080/search?q=<query>`.
4. Set **Search Result Count = 3** and **Concurrent Requests = 2**. On your CPU,
   RAG over 5+ raw HTML pages is what stalls the model — this matters more than
   it looks.
5. Pick your model from the **dropdown at the top-left of the chat** — this is
   your model switcher, just like changing Claude models. You'll see **`joe`**
   (fast) and **`joe-7b`** (smart); click either to switch, even mid-conversation.
   Start on `joe` and only reach for `joe-7b` when a hard problem is worth the wait.

Toggle the **globe icon** in a chat to run a Tor-routed research query.

> Prettier labels (optional): Admin Panel → Settings → Models lets you set a
> friendly display name and description per model — e.g. name them "Joe (fast)"
> and "Joe (smart)" so the dropdown reads clearly. This is cosmetic; the
> underlying models stay `joe` and `joe-7b`.

## Step 7 — Coding

See `docs/CODING.md` to connect VS Code (Continue.dev) or Aider to your local
Ollama.

---

## Daily commands

```powershell
docker compose up -d          # start the web/search/tor side
docker compose down           # stop it (Ollama keeps running natively)
docker compose logs -f        # watch logs
ollama list                   # installed models
ollama ps                     # what's loaded right now
```

## If web search returns nothing

Run through `docs/PRIVACY.md`'s checklist and the gotchas in the root
`README.md`. 90% of the time it's (a) JSON not enabled in `settings.yml`, or
(b) Tor still bootstrapping / timeouts too low.
