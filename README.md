# vision-qwen-model

Build, package, publish, and deploy `snipkode/vision-qwen:2b-q4` as a Docker Model Runner OCI model artifact. This is a distributable model artifact, not a conventional Docker application image.

## Model

Qwen3-VL-2B-Instruct, GGUF `Q4_K_M`, with the matching `mmproj-Qwen3VL-2B-Instruct-Q8_0.gguf` vision projector. CPU-only inference through the Docker Model Runner `llama.cpp` backend. See `MODEL.md` for architecture, checksums, and license.

## Prerequisites

- Ubuntu 24.04
- Docker Engine with Docker Model Runner
- `llama.cpp` backend, CPU mode
- Hugging Face CLI: `pip install 'huggingface_hub[cli]'`
- `curl`, `python3`, `file`, `sha256sum`, `strings`, `od`

Enable the CPU backend on Docker Engine:

```bash
sudo docker model start-runner --backend llama.cpp --gpu none
```

## Build

Downloads the official GGUF files, validates magic bytes/quantization/projector metadata, writes `checksums.txt`, packages the OCI artifact, and inspects it locally.

```bash
chmod +x build.sh publish.sh deploy.sh test-vision.sh
./build.sh
```

Override if needed:

```bash
MODEL_DIR=/var/tmp/qwen-model CONTEXT_SIZE=4096 TARGET=docker.io/snipkode/vision-qwen:2b-q4 ./build.sh
```

## Publish

Requires Docker Hub authentication for the `snipkode` namespace.

```bash
export DOCKERHUB_USERNAME=snipkode
./publish.sh
```

The script runs `docker model push` and then `docker model inspect --remote` against `docker.io/snipkode/vision-qwen:2b-q4`.

## Deploy on another Ubuntu machine

No manual GGUF download is required.

```bash
./deploy.sh
```

The script checks Docker and Model Runner, starts the CPU backend if needed, derives `OMP_NUM_THREADS` from `nproc`, pulls `docker.io/snipkode/vision-qwen:2b-q4`, loads it detached, and verifies the OpenAI-compatible `/models` endpoint.

To override threads:

```bash
OMP_NUM_THREADS=4 ./deploy.sh
```

## Test vision inference

```bash
./test-vision.sh /path/to/image.png
```

The script sends the image as a base64 `data:` URL through the OpenAI-compatible chat completions API and prints the model's description.

Default API base:

```text
http://localhost:12434/engines/llama.cpp/v1
```

Text-only smoke test:

```bash
curl -sS http://localhost:12434/engines/llama.cpp/v1/chat/completions \
  -H 'Content-Type: application/json' \
  -d '{"model":"docker.io/snipkode/vision-qwen:2b-q4","messages":[{"role":"user","content":"Reply with OK."}],"max_tokens":16}'
```

## Environment variables

| Variable | Default | Used by |
|---|---|---|
| `TARGET` | `docker.io/snipkode/vision-qwen:2b-q4` | `build.sh`, `publish.sh`, `deploy.sh` |
| `MODEL_DIR` | `./model` | `build.sh` |
| `CONTEXT_SIZE` | `4096` | `build.sh` |
| `DMR_API` | `http://localhost:12434/engines/llama.cpp/v1` | `deploy.sh`, `test-vision.sh` |
| `MODEL_REF` | `docker.io/snipkode/vision-qwen:2b-q4` | `test-vision.sh` |
| `DOCKERHUB_USERNAME` | unset | `publish.sh` |
| `OMP_NUM_THREADS` | `nproc` | `deploy.sh` |

## Verification status

Verified on this host:

- Docker Model Runner CLI/server available and running.
- `docker model package` supports `--gguf`, `--mmproj`, `--context-size`, and `--license`.
- OpenAI-compatible `/models` endpoint returned HTTP `200`.
- Source GGUF and projector hashes recorded in `checksums.txt`.

Not verified yet:

- Push to Docker Hub.
- Pull from a second machine.
- End-to-end image analysis through the packaged artifact.

These require Docker Hub credentials for `alam` and a second Ubuntu host, and are not simulated by the scripts.
