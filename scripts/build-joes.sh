#!/usr/bin/env bash
# Builds BOTH Joes so you can switch between them in Open WebUI's model dropdown
# (top-left of the chat), the same way you switch Claude models:
#
#   joe      - fast daily driver   (qwen2.5-coder:3b)
#   joe-7b   - smarter, slower      (qwen2.5-coder:7b)
#
# Both carry the same guardrails and personality. Run from the repo root:
#   ./scripts/build-joes.sh
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"

echo "=== Building 'joe' (fast, 3B) ==="
BASE=qwen2.5-coder:3b NAME=joe "$HERE/build-guarded-model.sh"

echo
echo "=== Building 'joe-7b' (smart, 7B) ==="
# FORCE=1: guardrails were just reviewed above, skip the second confirmation.
FORCE=1 BASE=qwen2.5-coder:7b NAME=joe-7b "$HERE/build-guarded-model.sh"

echo
echo "Both models built."
echo "In Open WebUI, click the model name at the top-left of a chat to switch"
echo "between 'joe' (fast) and 'joe-7b' (smart) -- you can even switch mid-chat."
