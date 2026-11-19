#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ID="Qwen/Qwen3-VL-2B-Instruct-GGUF"
MODEL_FILE="Qwen3VL-2B-Instruct-Q4_K_M.gguf"
PROJ_FILE="mmproj-Qwen3VL-2B-Instruct-Q8_0.gguf"
MODEL_DIR="${MODEL_DIR:-$SCRIPT_DIR/model}"
TARGET="${TARGET:-docker.io/snipkode/vision-qwen:2b-q4}"
CONTEXT_SIZE="${CONTEXT_SIZE:-4096}"

for cmd in docker sha256sum strings od; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "Missing command: $cmd" >&2; exit 1; }
done

if command -v hf >/dev/null 2>&1; then
  HF_BIN=hf
elif command -v huggingface-cli >/dev/null 2>&1; then
  HF_BIN=huggingface-cli
else
  echo "Install Hugging Face CLI: pip install 'huggingface_hub[cli]'" >&2
  exit 1
fi

if ! docker model version >/dev/null 2>&1; then
  echo "Docker Model Runner CLI is required" >&2
  exit 1
fi

SUDO=""
if [[ $EUID -ne 0 ]]; then
  SUDO=sudo
fi

if ! docker model status >/dev/null 2>&1 || docker model status | grep -qi "not running"; then
  $SUDO docker model start-runner --backend llama.cpp --gpu none
fi

mkdir -p "$MODEL_DIR"
"$HF_BIN" download "$REPO_ID" "$MODEL_FILE" --local-dir "$MODEL_DIR"
"$HF_BIN" download "$REPO_ID" "$PROJ_FILE" --local-dir "$MODEL_DIR"

GGUF="$MODEL_DIR/$MODEL_FILE"
MMPROJ="$MODEL_DIR/$PROJ_FILE"

test -s "$GGUF"
test -s "$MMPROJ"

for file in "$GGUF" "$MMPROJ"; do
  magic="$(od -An -tx1 -N4 "$file" | tr -d ' \n')"
  test "$magic" = "47475546" || { echo "Invalid GGUF magic: $file" >&2; exit 1; }
done

strings "$GGUF" | grep -m1 -q "Q4_K_M" || { echo "Q4_K_M metadata not found" >&2; exit 1; }
strings "$MMPROJ" | grep -m1 -qi "clip" || { echo "CLIP projector metadata not found" >&2; exit 1; }

sha256sum "$GGUF" "$MMPROJ" | sed "s|$MODEL_DIR/||" > "$SCRIPT_DIR/checksums.txt"

docker model package \
  --gguf "$GGUF" \
  --mmproj "$MMPROJ" \
  --context-size "$CONTEXT_SIZE" \
  --license "$SCRIPT_DIR/LICENSE" \
  "$TARGET"

docker model inspect "$TARGET"
