# High-concurrency ladder — SGLang EAGLE s=3, 50k window

Thinking-off, 512 output tokens, 3 reps drop-first. Serve: `max_running_requests=96`, decode graphs to 48, `max_total_tokens=196608`. After READY, `available_gpu_mem=51.63 GB`. Host MemAvailable after C96 still ~51 GiB.

| C | ok_rate | median agg tok/s |
|---:|---:|---:|
| 8 | 1.00 | 214.9 |
| 12 | 1.00 | 283.0 |
| 16 | 1.00 | 309.3 |
| 24 | 1.00 | 374.8 |
| 32 | 1.00 | 422.6 |
| 48 | 1.00 | 536.6 |
| 64 | 1.00 | 606.5 |
| 80 | 1.00 | **693.5** |
| 96 | 1.00 | 691.5 |

Peak **C80 = 693.5** aggregate tok/s. C96 is flat (compute plateau, not memory). Zero request failures through C96. Memory was not the stop.

Compare: vLLM published thinking-on C6 = 252; vLLM K=7 C6 = 271. This ladder is thinking-off 512-out (same shape as the vLLM K=7 concurrency lane).
