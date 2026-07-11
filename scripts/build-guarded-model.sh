#!/usr/bin/env bash
# Builds your guarded model by wrapping a base Ollama model with the system
# prompt in guardrails/system-prompt.txt. (Linux / macOS / WSL / Git Bash.)
#
# Usage, from the repo root:
#   ./scripts/build-guarded-model.sh
#   BASE=qwen2.5-coder:3b NAME=joe ./scripts/build-guarded-model.sh
set -euo pipefail

BASE="${BASE:-qwen2.5-coder:7b}"
NAME="${NAME:-joe}"
NUM_CTX="${NUM_CTX:-4096}"
TEMPERATURE="${TEMPERATURE:-0.4}"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROMPT="$ROOT/guardrails/system-prompt.txt"
MODELFILE="$(mktemp)"
trap 'rm -f "$MODELFILE"' EXIT

[ -f "$PROMPT" ] || { echo "Can't find $PROMPT" >&2; exit 1; }

echo "Pulling base model '$BASE' (skip if already present)..."
ollama pull "$BASE"

{
  echo "FROM $BASE"
  echo "PARAMETER num_ctx $NUM_CTX"
  echo "PARAMETER temperature $TEMPERATURE"
  echo 'SYSTEM """'
  cat "$PROMPT"
  echo '"""'
} > "$MODELFILE"

echo "Building guarded model '$NAME' from '$BASE'..."
ollama create "$NAME" -f "$MODELFILE"

echo
echo "Done. Your guarded model is '$NAME'."
echo "Edit guardrails/system-prompt.txt and rerun this script to change the rules."
