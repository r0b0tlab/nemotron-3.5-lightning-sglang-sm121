#!/usr/bin/env bash
set -Eeuo pipefail
docker rm -f nemotron-lightning-sglang-mtp-s3 2>/dev/null || true
echo "SGLang container removed. Restore your previous vLLM primary with your local restore script."
