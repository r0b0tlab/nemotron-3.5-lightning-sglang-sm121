#!/usr/bin/env bash
# SGLang MTP EAGLE steps=3 production window (max_model_len=50016).
set -Eeuo pipefail
MODEL_CKPT="${MODEL_CKPT:?Set MODEL_CKPT to the local Nemotron Lightning weights directory}"
IMAGE="${IMAGE:-lmsysorg/sglang:dev-cu13-nemotron3-5-lightning}"
CONTAINER_NAME="${CONTAINER_NAME:-nemotron-lightning-sglang-mtp-s3}"
PORT="${PORT:-8000}"
CTX_LEN="${CTX_LEN:-50016}"
MAX_TOTAL="${MAX_TOTAL:-65536}"
STEPS="${STEPS:-3}"
MAX_RUNNING="${MAX_RUNNING:-6}"
GRAPH_BS="${GRAPH_BS:-16}"
CACHE_ROOT="${CACHE_ROOT:-$HOME/.cache/sglang-lightning}"
mkdir -p "$CACHE_ROOT"
if docker container inspect "$CONTAINER_NAME" >/dev/null 2>&1; then
  printf 'container already exists: %s\n' "$CONTAINER_NAME" >&2
  exit 3
fi
docker run -d \
  --name "$CONTAINER_NAME" \
  --gpus all --ipc=host --shm-size=64g \
  --ulimit memlock=-1:-1 --cap-add=IPC_LOCK --cap-add=SYS_NICE \
  --publish "$PORT:8000" \
  --env SGLANG_ALLOW_OVERWRITE_LONGER_CONTEXT_LEN=1 \
  --volume "$MODEL_CKPT:/model:ro" \
  --volume "$CACHE_ROOT:/root/.cache/sglang" \
  "$IMAGE" \
  sglang serve \
  --model-path /model \
  --served-model-name nvidia/nemotron-3.5-lightning-30b-a3b \
  --speculative-algorithm EAGLE \
  --speculative-num-steps "$STEPS" \
  --speculative-eagle-topk 1 \
  --mamba-backend flashinfer \
  --mamba-ssm-dtype float16 \
  --enable-mamba-cache-stochastic-rounding \
  --mamba-cache-philox-rounds 5 \
  --mem-fraction-static 0.85 \
  --cuda-graph-max-bs-decode 16 \
  --kv-cache-dtype fp8_e4m3 \
  --context-length "$CTX_LEN" \
  --max-total-tokens "$MAX_TOTAL" \
  --max-running-requests "$MAX_RUNNING" \
  --cuda-graph-max-bs-decode "$GRAPH_BS" \
  --reasoning-parser nemotron_3 \
  --tool-call-parser qwen3_coder \
  --enable-metrics \
  --attention-backend flashinfer \
  --host 0.0.0.0 \
  --port 8000
echo "launched $CONTAINER_NAME MTP/EAGLE steps=$STEPS ctx=$CTX_LEN running=$MAX_RUNNING graph_bs=$GRAPH_BS total=$MAX_TOTAL"
