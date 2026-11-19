#!/usr/bin/env bash
set -euo pipefail

TARGET="${TARGET:-docker.io/snipkode/vision-qwen:2b-q4}"
DMR_API="${DMR_API:-http://localhost:12434/engines/llama.cpp/v1}"

command -v docker >/dev/null 2>&1 || { echo "docker is required" >&2; exit 1; }
command -v curl >/dev/null 2>&1 || { echo "curl is required" >&2; exit 1; }
docker model version >/dev/null 2>&1 || { echo "Docker Model Runner CLI is required" >&2; exit 1; }

SUDO=""
if [[ $EUID -ne 0 ]]; then
  SUDO=sudo
fi

if ! docker model status >/dev/null 2>&1 || docker model status | grep -qi "not running"; then
  $SUDO docker model start-runner --backend llama.cpp --gpu none
fi

if ! docker model status | grep -Eqi "llama\.cpp[[:space:]]+Installed"; then
  echo "llama.cpp backend is not installed" >&2
  exit 1
fi

export OMP_NUM_THREADS="${OMP_NUM_THREADS:-$(nproc)}"

docker model pull "$TARGET"
docker model run -d "$TARGET"

for _ in $(seq 1 30); do
  if curl -fsS "$DMR_API/models" >/dev/null 2>&1; then
    break
  fi
  sleep 2
done

curl -fsS "$DMR_API/models"
echo
docker model ps
