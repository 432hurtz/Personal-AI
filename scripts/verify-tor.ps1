# Confirms SearXNG's outbound traffic is actually going through Tor. (Windows)
# Run from anywhere after `docker compose up -d`.
$ErrorActionPreference = "Stop"

Write-Host "Checking that the searxng container exits via Tor..."
$result = docker exec searxng curl -s --max-time 30 `
  --socks5-hostname tor:9050 https://check.torproject.org/api/ip

Write-Host "Response: $result"
if ($result -match '"IsTor":true') {
  Write-Host "OK: traffic is going through Tor." -ForegroundColor Green
} else {
  Write-Host "NOT OK: did not see IsTor:true." -ForegroundColor Yellow
  Write-Host "Tor may still be bootstrapping (wait a minute) or the proxy is misconfigured."
  Write-Host "Check:  docker compose logs tor"
  exit 1
}
