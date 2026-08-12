# NVIDIA Nemotron 3.5 Lightning — SGLang SM121 reproducibility suite

Repository: https://github.com/r0b0tlab/nemotron-3.5-lightning-sglang-sm121

Public reproducibility materials for serving NVIDIA Nemotron 3.5 Lightning NVFP4 with SGLang on NVIDIA GB10 / SM121. No weights, datasets, credentials, or raw BFCL traces.

## Identity

- Served model ID: `nvidia/nemotron-3.5-lightning-30b-a3b`
- Engine: SGLang day-0 Lightning (`lmsysorg/sglang:dev-cu13-nemotron3-5-lightning` @ `sha256:e5e3cdb9afefc182ac2427345c27e17ec1c8eddb568732fb3343fd832cee22f1`, commit `d59c1ddf`)
- Spec: MTP via EAGLE, `num_steps=3`, `eagle_topk=1`
- Attention: FlashInfer · MoE: Marlin (required for W4A16_NVFP4) · KV: FP8 e4m3
- Production window: `max_model_len=50016`
- Thinking-on complete-answer budgets: GSM8K 49152, QA/IFEval/HumanEval 32768, systems/BFCL 8192
- r0b0bench 1.0.0rc2 @ `e0f0bf6` + `thinking-allowed.patch` (`a243d103…`)

## Reproduce

```bash
export MODEL_CKPT=/absolute/path/to/weights
export IMAGE=lmsysorg/sglang:dev-cu13-nemotron3-5-lightning
# or ghcr.io/r0b0tlab/nemotron-lightning-sglang-sm121:sm121-mtp-eagle-s3 after GHCR publish
bash runtime/launch.sh
```

Wait for `/v1/models` to report `nvidia/nemotron-3.5-lightning-30b-a3b` and `max_model_len=50016`.

```bash
python3 -m venv .venv
. .venv/bin/activate
python -m pip install -e './benchmark[bfcl,dev]'
export R0B0BENCH_CHAT_TEMPLATE_KWARGS='{"thinking":true,"enable_thinking":true}'
export TOKENIZER="$MODEL_CKPT"
export OUTPUT=/tmp/sglang-lightning-r0b0bench
bash scripts/run_benchmark.sh
```

## Results

Filled after the matched thinking-on 11-lane run. 1M NIAH 75% is a reused capacity row (749,808 tokens PASS).

## Boundary

Never commit weights, datasets, `.env`, tokens, raw BFCL traces, or host-absolute private paths.
