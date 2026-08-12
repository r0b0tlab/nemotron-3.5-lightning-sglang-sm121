# 1M NIAH 75% — reused capacity row

Source: SGLang MTP EAGLE s=3, 1M override, 2026-08-12.
Image: `lmsysorg/sglang:dev-cu13-nemotron3-5-lightning` @ `sha256:e5e3cdb9afefc182ac2427345c27e17ec1c8eddb568732fb3343fd832cee22f1`

| Field | Value |
|---|---|
| depth | 749,808 constructed prompt tokens (= 0.75 × (1,000,000 − 256)) |
| result | PASS — exact needle `R0B0-NIAH-7K3M`, finish `stop`, HTTP 200 |
| token parity | server `usage.prompt_tokens` == 749,808 |
| wall | 550.7 s |
| reasoning_tokens | 0 |
| infra errors | 0 |
| scope | single-depth `--only niah`; `invalid_for_publish=true` |

This row is capacity evidence only. The 11-lane production NIAH is 25/50/90 of the 50,016 window.
