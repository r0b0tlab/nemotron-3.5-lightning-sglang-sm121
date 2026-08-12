#!/usr/bin/env bash
set -Eeuo pipefail
docker rm -f nemotron-lightning-sglang-mtp-s3 2>/dev/null || true
exec bash /home/r0b0tdgx/artifacts/nemotron-lightning-optimization/niah-1m-20260811T1223Z/restore-primary.sh
