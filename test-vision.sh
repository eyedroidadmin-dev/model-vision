#!/usr/bin/env bash
set -euo pipefail

IMAGE="${1:-${IMAGE:-}}"
DMR_API="${DMR_API:-http://localhost:12434/engines/llama.cpp/v1}"
MODEL_REF="${MODEL_REF:-docker.io/snipkode/vision-qwen:2b-q4}"

command -v file >/dev/null 2>&1 || { echo "file is required" >&2; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "python3 is required" >&2; exit 1; }

test -n "$IMAGE" || { echo "Usage: $0 <image-path>" >&2; exit 1; }
test -f "$IMAGE" || { echo "Image not found: $IMAGE" >&2; exit 1; }

MIME="$(file --mime-type -b "$IMAGE")"

python3 - "$IMAGE" "$DMR_API/chat/completions" "$MODEL_REF" "$MIME" <<'PY'
import base64
import json
import sys
import urllib.request

path, url, model, mime = sys.argv[1:5]
with open(path, "rb") as handle:
    payload_image = base64.b64encode(handle.read()).decode("ascii")

payload = {
    "model": model,
    "temperature": 0,
    "max_tokens": 256,
    "messages": [
        {
            "role": "user",
            "content": [
                {"type": "text", "text": "Describe the image in one sentence."},
                {
                    "type": "image_url",
                    "image_url": {"url": f"data:{mime};base64,{payload_image}"},
                },
            ],
        }
    ],
}

request = urllib.request.Request(
    url,
    data=json.dumps(payload).encode("utf-8"),
    headers={"Content-Type": "application/json"},
)
with urllib.request.urlopen(request, timeout=300) as response:
    result = json.load(response)

print(result["choices"][0]["message"]["content"])
PY
