# Builds your guarded model by wrapping a base Ollama model with the system
# prompt in guardrails/system-prompt.txt.
#
# Usage (PowerShell, from the repo root):
#   .\scripts\build-guarded-model.ps1                       # uses defaults
#   .\scripts\build-guarded-model.ps1 -Base qwen2.5-coder:3b -Name joe
#
# After it runs, use the model named 'joe' in Open WebUI or the CLI:
#   ollama run joe

param(
  [string]$Base = "qwen2.5-coder:7b",   # base model to wrap
  [string]$Name = "joe",        # name of your guarded model
  [int]$NumCtx  = 4096,                 # context window (keep modest on CPU)
  [double]$Temperature = 0.4            # lower = more deterministic
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$promptPath = Join-Path $root "guardrails\system-prompt.txt"
$modelfile  = Join-Path $env:TEMP "Modelfile.joe"

if (-not (Test-Path $promptPath)) {
  throw "Can't find $promptPath"
}

Write-Host "Pulling base model '$Base' (skip if already present)..."
ollama pull $Base

$system = Get-Content $promptPath -Raw

@"
FROM $Base
PARAMETER num_ctx $NumCtx
PARAMETER temperature $Temperature
SYSTEM """
$system
"""
"@ | Set-Content -Path $modelfile -Encoding UTF8

Write-Host "Building guarded model '$Name' from '$Base'..."
ollama create $Name -f $modelfile
Remove-Item $modelfile -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "Done. Your guarded model is '$Name'." -ForegroundColor Green
Write-Host "Edit guardrails\system-prompt.txt and rerun this script to change the rules."
