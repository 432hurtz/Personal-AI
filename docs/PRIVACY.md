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

## Hardening checklist (optional, all local)

- [ ] Confirm Tor egress: `.\scripts\verify-tor.ps1` → `IsTor:true`.
- [ ] Keep Open WebUI on `127.0.0.1:3000` — never change it to `0.0.0.0`. The
      Ollama API has **no authentication**; exposing it exposes everything.
- [ ] Set a real `secret_key` in `searxng/settings.yml`.
- [ ] If you want *nothing* on disk, clear Open WebUI chat history periodically,
      or use `docker compose down -v` to nuke its volume (also deletes settings).
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
