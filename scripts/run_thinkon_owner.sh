#!/usr/bin/env bash
# Durable thinking-on 11-lane owner for SGLang MTP EAGLE s=3.
set -uo pipefail
ROOT=/home/r0b0tdgx/projects/nemotron-3.5-lightning-sglang-sm121
OUT=/home/r0b0tdgx/artifacts/nemotron-lightning-optimization/sglang-sm121-20260812/matched-evals/thinkon-core-subset
TOK='/home/r0b0tdgx/Documents/Nemotron Lightning/Weights'
mkdir -p "$OUT" "$OUT/../logs"
cd "$ROOT"
# shellcheck disable=SC1091
. .venv/bin/activate
export TOKENIZER="$TOK"
export OUTPUT="$OUT"
export R0B0BENCH_BIN="$ROOT/.venv/bin/r0b0bench"
export R0B0BENCH_CHAT_TEMPLATE_KWARGS='{"thinking":true,"enable_thinking":true}'
export R0B0BENCH_CANARY_MAX_TOKENS=8192
export R0B0BENCH_BFCL_PYTHON="$ROOT/.venv/bin/python"
export R0B0BENCH_BFCL_SCRIPTS="$ROOT/benchmark/scripts/bfcl"
export R0B0BENCH_SERVED_MODEL='nvidia/nemotron-3.5-lightning-30b-a3b'
export R0B0BENCH_GSM8K_DATA=/home/r0b0tdgx/datasets/gsm8k/test.jsonl
export R0B0BENCH_HUMANEVAL_DATA=/home/r0b0tdgx/datasets/humaneval/HumanEval.jsonl
export R0B0BENCH_IFEVAL_DATA=/home/r0b0tdgx/datasets/ifeval/input_data.jsonl
export R0B0BENCH_QA_DATA=/home/r0b0tdgx/datasets/qa/arc_easy_test.jsonl
export BFCL_NUM_THREADS=1
export BFCL_MAX_TOKENS=8192
export BFCL_HTTP_TIMEOUT=7200
export BFCL_MAX_RETRIES=3
export BFCL_PROJECT_ROOT="$OUT/bfcl-project"
export TIMEOUT=7200
mkdir -p "$BFCL_PROJECT_ROOT"
echo "OWNER_START $(date -u +%FT%TZ)" | tee -a "$OUT/../logs/thinkon-owner.log"
bash scripts/run_benchmark.sh >>"$OUT/../logs/thinkon-owner.log" 2>&1
rc=$?
echo "OWNER_EXIT=$rc $(date -u +%FT%TZ)" | tee -a "$OUT/../logs/thinkon-owner.log"
exit $rc
