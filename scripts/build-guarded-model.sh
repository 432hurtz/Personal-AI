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
HASHFILE="$ROOT/guardrails/.last-build-hash"
MODELFILE="$(mktemp)"
trap 'rm -f "$MODELFILE"' EXIT

[ -f "$PROMPT" ] || { echo "Can't find $PROMPT" >&2; exit 1; }

# Guard: if the guardrails changed since the last build, make the human notice.
# A self-edit (Joe rewriting its own rules) can never slip into a rebuild
# unreviewed -- you have to confirm (set FORCE=1 to skip the prompt).
CURRENT_HASH="$(sha256sum "$PROMPT" | awk '{print $1}')"
if [ -f "$HASHFILE" ]; then
  if [ "$(cat "$HASHFILE")" != "$CURRENT_HASH" ]; then
    echo
    echo "NOTICE: guardrails/system-prompt.txt has CHANGED since the last build."
    echo "Review it (especially OFF LIMITS and SYSTEM & FILE CONTROL) before rebuilding."
    if [ "${FORCE:-0}" != "1" ]; then
      printf "Rebuild Joe with these changed rules? (y/N) "
      read -r ans
      [ "$ans" = "y" ] || { echo "Aborted. Nothing was rebuilt."; exit 1; }
    fi
  else
    echo "Guardrails unchanged since last build."
  fi
else
  echo "First build (no previous guardrails hash on record)."
fi

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

# Record the hash we just built from, so the next run can detect changes.
printf '%s' "$CURRENT_HASH" > "$HASHFILE"

echo
echo "Done. Your guarded model is '$NAME'."
echo "Edit guardrails/system-prompt.txt and rerun this script to change the rules."
