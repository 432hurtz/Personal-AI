# Builds BOTH Joes so you can switch between them in Open WebUI's model dropdown
# (top-left of the chat), the same way you switch Claude models:
#
#   joe      - fast daily driver   (qwen2.5-coder:3b)  ~5-9 tok/s on your CPU
#   joe-7b   - smarter, slower      (qwen2.5-coder:7b)  ~2-4 tok/s on your CPU
#
# Both carry the same guardrails (system-prompt.txt) and personality
# (personality.txt). Run from the repo root:  .\scripts\build-joes.ps1

$ErrorActionPreference = "Stop"
$here = $PSScriptRoot

Write-Host "=== Building 'joe' (fast, 3B) ===" -ForegroundColor Cyan
& "$here\build-guarded-model.ps1" -Base qwen2.5-coder:3b -Name joe

Write-Host ""
Write-Host "=== Building 'joe-7b' (smart, 7B) ===" -ForegroundColor Cyan
# -Force: the guardrails were just reviewed for the build above, so skip the
# second confirmation prompt.
& "$here\build-guarded-model.ps1" -Base qwen2.5-coder:7b -Name joe-7b -Force

Write-Host ""
Write-Host "Both models built." -ForegroundColor Green
Write-Host "In Open WebUI, click the model name at the top-left of a chat to switch"
Write-Host "between 'joe' (fast) and 'joe-7b' (smart) -- you can even switch mid-chat."
