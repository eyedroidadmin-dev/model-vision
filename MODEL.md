# MODEL.md

## Artifact

- Reference: `docker.io/snipkode/vision-qwen:2b-q4`
- Type: Docker Model Runner OCI model artifact (GGUF + MMProj), not a Dockerfile application image
- Runtime: Docker Model Runner with `llama.cpp` backend
- Execution: CPU-only, no CUDA dependency

## Source

- Base model: `Qwen/Qwen3-VL-2B-Instruct`
- GGUF repository: `Qwen/Qwen3-VL-2B-Instruct-GGUF`
- Upstream metadata: `pipeline_tag=image-text-to-text`, `base_model=Qwen/Qwen3-VL-2B-Instruct`
- Upstream license: `apache-2.0`

## Components

| File | Role | Quantization | SHA256 |
|---|---|---|---|
| `Qwen3VL-2B-Instruct-Q4_K_M.gguf` | language model | Q4_K_M | `089d75c52f4b7ffc56ba998ffc50aae89fcafc755f9e7208aacca281dca6c2ae` |
| `mmproj-Qwen3VL-2B-Instruct-Q8_0.gguf` | vision projector | Q8_0 | `f9a68fabba69c3b81e153367b2c7521030b0fa8bb0de400c9599c8e6725f9c82` |

The projector is part of the same upstream GGUF repository as the language model. An incompatible or missing projector is treated as a build failure by `build.sh`.

## Architecture

- Architecture: `qwen3vl`
- Parameters: `1.7B`
- Language quantization: `Q4_K_M`
- Projector: `clip`, `406.96M` parameters, embedding length `1024`, dimensions `2048`
- Context size packaged into the artifact: `4096` tokens
- Capabilities: `tools`, `completion`, `vision`
- Approximate packaged weight size: `1.6 GB`

## Resource profile

- Designed for CPU-only inference.
- Single concurrent inference request.
- Context size kept in the `2048-4096` range.
- Thread count is not hardcoded. `deploy.sh` sets `OMP_NUM_THREADS` from `nproc` and allows an override.

## Verification log

- Hugging Face API metadata checked: `license=apache-2.0`, `pipeline_tag=image-text-to-text`.
- Both GGUF files verified with `sha256sum`; hashes match `checksums.txt`.
- GGUF runtime metadata previously validated with Ollama: `architecture qwen3vl`, `Q4_K_M`, `vision` capability, compatible `clip` projector.
- Docker Model Runner CLI `v1.2.6` / server `v1.2.8` available and running on this host.
- OpenAI-compatible endpoint probed: `GET http://localhost:12434/engines/llama.cpp/v1/models` returned HTTP `200`.
- OCI artifact pushed to `localhost:5000/vision-qwen:2b-q4`, pulled locally, and inspected as `architecture qwen3vl`, `1.72B`, `MOSTLY_Q4_K_M`, context `4096`, size `1.03GiB`.
- `docker model run localhost:5000/vision-qwen:2b-q4 "Reply with OK."` installed the `llama.cpp` backend and returned `OK`.
- Vision inference via the OpenAI-compatible API correctly described `linknet-logo.png`.
- Docker Hub push and second-machine pull are not verified yet.
