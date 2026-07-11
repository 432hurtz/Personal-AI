#!/usr/bin/env bash
# Confirms SearXNG's outbound traffic is actually going through Tor.
# Run from anywhere after `docker compose up -d`.
set -euo pipefail

echo "Checking that the searxng container exits via Tor..."
result="$(docker exec searxng curl -s --max-time 30 \
  --socks5-hostname tor:9050 https://check.torproject.org/api/ip || true)"

echo "Response: $result"
if echo "$result" | grep -q '"IsTor":true'; then
  echo "OK: traffic is going through Tor."
else
  echo "NOT OK: did not see IsTor:true. Tor may still be bootstrapping"
  echo "(give it a minute after startup) or the proxy config is wrong."
  echo "Check:  docker compose logs tor"
  exit 1
fi
