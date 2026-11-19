#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${TARGET:-docker.io/snipkode/vision-qwen:2b-q4}"
SOURCE="${SOURCE:-$TARGET}"

command -v docker >/dev/null 2>&1 || { echo "docker is required" >&2; exit 1; }
docker model version >/dev/null 2>&1 || { echo "Docker Model Runner CLI is required" >&2; exit 1; }

if [[ -n "${DOCKERHUB_USERNAME:-}" ]]; then
  docker login -u "$DOCKERHUB_USERNAME" docker.io
else
  echo "Set DOCKERHUB_USERNAME or run: docker login docker.io" >&2
fi

docker model inspect "$SOURCE" >/dev/null
if [[ "$SOURCE" != "$TARGET" ]]; then
  docker model tag "$SOURCE" "$TARGET"
fi
docker model push "$TARGET"
docker model inspect --remote "$TARGET"
