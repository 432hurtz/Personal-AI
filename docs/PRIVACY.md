# Privacy — what "absolute privacy" does and doesn't mean

You asked for absolute privacy. Here's the precise version, so you're not
trusting a slogan.

## What IS fully private

- **Inference never leaves your machine.** The model runs in native Ollama on
  your laptop. Your prompts, your code, your conversations — none of it is sent
  to any provider. There is no account, no API key to a cloud model, no
  "improve the model with your data" pipeline. `ENABLE_OPENAI_API=false` keeps
  Open WebUI from reaching external model providers.
- **No telemetry.** Open WebUI's anonymous telemetry is disabled
  (`ANONYMIZED_TELEMETRY=false`, `DO_NOT_TRACK=true`, `SCARF_NO_ANALYTICS=true`).
- **Not exposed to your network.** Open WebUI binds to `127.0.0.1` only.
  Nothing on your Wi-Fi/LAN can reach it. SearXNG and Tor have no host ports at
  all — only Open WebUI (inside the Docker network) can reach SearXNG.

## What CANNOT be fully private — and how Tor helps

**Web research touches the network. That's physics, not a config bug.** When
you search, a request has to leave your machine and hit real websites.

Tor changes *who appears to be asking*, not *whether someone asked*:

- Your search queries exit from a Tor node, not your home IP. The sites you
  research don't see your address.
- `socks5h://tor:9050` resolves DNS **through Tor too**, so you don't leak
  domain lookups to your ISP's resolver.
- What Tor does NOT do: hide from *yourself* that you searched (it's in Open
  WebUI's local history), and it can't stop a website from fingerprinting the
  content of the query. Also, Tor exit nodes can see unencrypted traffic — stick
  to HTTPS results (the default engines here are HTTPS).

So: **"who is asking" is hidden; "that a query happened" is not.** For pure
local Q&A with the globe toggle OFF, nothing leaves the machine at all.

## What your ISP and the websites you research can see

You said you hate ISP and website tracking, so here's the exact accounting.

**Your ISP sees:**
- By default, that you connect to the **Tor network** (the entry/guard node).
  It sees you *use* Tor — not what you search, not which sites you read, not the
  content. **If you don't want your ISP to see even that, turn on bridges**
  (next section): with obfs4 bridges the connection is obfuscated and doesn't
  look like Tor.
- A few **one-time clearnet downloads** during setup: Docker pulling the
  container images, and Ollama pulling models from `ollama.com`. These are not
  routed through Tor (doing so is slow and fragile). Your ISP sees you
  downloaded "some Docker images" and "some Ollama models" — not your usage.
  After setup, day-to-day research traffic is all Tor.

**The websites you research see:**
- A **Tor exit node's IP**, not yours — for both the search query *and* (now)
  the page-content fetch. This was the one real leak in the original setup:
  Open WebUI fetches the pages behind search results to feed RAG, and that
  fetch used to leave from your real IP. It's now forced through Tor via
  `HTTP_PROXY=http://tor:8118` on the Open WebUI container. So the sites you
  actually read no longer see your address.
- No browser fingerprint from you, because *you* never load the page — Open
  WebUI does, server-side. SearXNG also proxies result images
  (`image_proxy: true`), so your browser doesn't fetch remote images directly.

**Trade-off:** routing page fetches through Tor makes research slower, and some
sites block Tor exits outright (you'll occasionally get a page that won't load).
That's the cost of not leaking your IP. To turn it off, delete the four
`*_PROXY` / `*_proxy` lines from `docker-compose.yml` and `docker compose up -d`
again — search stays on Tor, only the page fetch goes direct.

**Embeddings are fully local.** Open WebUI would normally download an embedding
model from HuggingFace the first time you use RAG. This setup avoids that
entirely: `RAG_EMBEDDING_ENGINE=ollama` + `RAG_EMBEDDING_MODEL=nomic-embed-text`
make embeddings run on your local Ollama, so nothing is downloaded at RAG time
and nothing leaves the machine. You just pull `nomic-embed-text` once during
setup (it's small and fast, even on your CPU).

## Onion (dark web) search

Because egress is `socks5h` through Tor, the transport can reach `.onion`
services natively — Tor resolves them itself, no DNS involved. This repo enables
two onion-indexing engines so `.onion` results show up alongside clearnet ones:

- **Ahmia** — clearnet-reachable index that filters out abuse material (CSAM).
- **Torch** — onion-only, unfiltered, broader but noisier and often stale.
- **not Evil** — deliberately left OFF (commented out in `searxng/settings.yml`).

This is turned on via `using_tor_proxy: true` in `settings.yml` plus
`&categories=general,onions` on the query URL in `docker-compose.yml`. To go
back to clearnet-only, drop `,onions` from that URL and rebuild.

Caveats: onion indexes are sparse and stale (expect dead links), onion
addresses rot (if Torch returns nothing, its `.onion` address in `settings.yml`
likely needs updating), and the dark web hosts plenty you may want off this
machine — that's what the `OFF LIMITS` block in your guardrails is for.

## Hide Tor from your ISP (obfs4 bridges) — optional

By default your ISP can see you connect to Tor (not what you do — just that Tor
is in use). To hide *that* too, route through **obfs4 bridges**: unlisted entry
points that scramble the traffic so it doesn't look like Tor to your ISP's deep
packet inspection.

This is opt-in via a separate Tor container (`tor/`) and a compose override, so
your normal setup stays simple. To enable:

```powershell
# 1. Get 2-3 obfs4 bridge lines from https://bridges.torproject.org (pick obfs4),
#    or Telegram @GetBridgesBot, or email bridges@torproject.org ("get transport obfs4").
# 2. Create your private bridges file and paste them in:
copy tor\bridges.conf.example tor\bridges.conf
notepad tor\bridges.conf
# 3. Bring the stack up WITH the bridge override (note the --build):
docker compose -f docker-compose.yml -f docker-compose.bridges.yml up -d --build
```

The bridge container exposes the same `tor:9050` (SOCKS) and `tor:8118` (HTTP)
the rest of the stack already uses, so nothing else changes — SearXNG, the RAG
page fetch, and onion search all now flow through bridges.

Notes:
- Bridges are slower and take longer to bootstrap. Give it a minute, then run
  `.\scripts\verify-tor.ps1` — you still expect `IsTor:true`.
- Check it connected: `docker compose logs -f tor` and look for
  `Bootstrapped 100% (done)`. If it stalls at a low %, your bridges are likely
  dead — grab fresh ones and rebuild.
- `tor/bridges.conf` is gitignored so your bridge lines stay private.
- To go back to plain Tor, just omit the `-f docker-compose.bridges.yml` part
  and `docker compose up -d` normally.

## Hardening checklist (optional, all local)

- [ ] Confirm Tor egress: `.\scripts\verify-tor.ps1` → `IsTor:true`.
- [ ] Keep Open WebUI on `127.0.0.1:3000` — never change it to `0.0.0.0`. The
      Ollama API has **no authentication**; exposing it exposes everything.
- [ ] Set a real `secret_key` in `searxng/settings.yml`.
- [ ] If you want *nothing* on disk, clear Open WebUI chat history periodically,
      or use `docker compose down -v` to nuke its volume (also deletes settings).
      For separating/deleting/purging individual chats and memory, see
      `docs/CONVERSATIONS.md`.
- [ ] Consider full-disk encryption (BitLocker on Win10 Pro) — the only real
      protection if the laptop is lost, since all your chats live in
      `./open-webui`.
- [ ] Windows itself phones home (telemetry, Defender). That's outside this
      stack; this project can't make Windows private, only this AI setup.

## The one honest caveat about the model

A 3-4B model hallucinates more than the big cloud models you may be used to.
For research, treat the **web-search results as the source of truth** and the
model as a summarizer. The guarded system prompt already tells it to do this,
but trust-but-verify anything factual it produces without a citation.
