#!/usr/bin/env python3
"""Concurrency ladder until failures or memory refusal.

Thinking-off 512-out, drop-first, 2 stable reps. Levels default 8,12,16,24,32,48.
Stops after two consecutive levels with error_rate>=0.25 or HTTP/connect collapse.
"""
from __future__ import annotations

import argparse
import json
import os
import time
import urllib.request
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime, timezone
from pathlib import Path

PROMPT = (
    "Write a short technical paragraph about hybrid Mamba-Transformer MoE "
    "inference on a single GB10. Do not use a list. End with the word DONE."
)


def one(url: str, model: str, max_tokens: int, timeout: float) -> dict:
    payload = {
        "model": model,
        "messages": [{"role": "user", "content": PROMPT}],
        "max_tokens": max_tokens,
        "temperature": 0,
        "chat_template_kwargs": {"thinking": False, "enable_thinking": False},
    }
    data = json.dumps(payload).encode()
    req = urllib.request.Request(
        f"{url.rstrip('/')}/v1/chat/completions",
        data=data,
        headers={"Content-Type": "application/json"},
    )
    t0 = time.perf_counter()
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            body = json.loads(resp.read().decode())
        elapsed = time.perf_counter() - t0
        usage = body.get("usage") or {}
        msg = ((body.get("choices") or [{}])[0].get("message") or {})
        comp = usage.get("completion_tokens") or 0
        return {
            "ok": resp.status == 200 and comp > 0,
            "http_status": resp.status,
            "elapsed_s": elapsed,
            "completion_tokens": comp,
            "tok_s": (comp / elapsed) if elapsed else 0.0,
            "content_ok": "DONE" in ((msg.get("content") or "").upper()),
        }
    except Exception as exc:
        return {
            "ok": False,
            "http_status": 0,
            "elapsed_s": time.perf_counter() - t0,
            "completion_tokens": 0,
            "tok_s": 0.0,
            "error": f"{type(exc).__name__}: {exc}",
        }


def run_level(url: str, model: str, c: int, max_tokens: int, reps: int, timeout: float) -> dict:
    rows = []
    for rep in range(reps):
        t0 = time.perf_counter()
        with ThreadPoolExecutor(max_workers=c) as pool:
            futs = [pool.submit(one, url, model, max_tokens, timeout) for _ in range(c)]
            results = [f.result() for f in as_completed(futs)]
        wall = time.perf_counter() - t0
        ok = sum(1 for r in results if r["ok"])
        toks = sum(r["completion_tokens"] for r in results)
        rows.append(
            {
                "rep": rep,
                "ok": ok,
                "n": c,
                "wall_s": wall,
                "aggregate_tok_s": toks / wall if wall else 0.0,
                "median_req_tok_s": sorted(r["tok_s"] for r in results)[len(results) // 2],
                "errors": [r.get("error") for r in results if not r["ok"]][:4],
            }
        )
    stable = rows[1:] if len(rows) > 1 else rows
    agg = sorted(r["aggregate_tok_s"] for r in stable)
    return {
        "concurrency": c,
        "reps": rows,
        "ok_rate": sum(r["ok"] for r in stable) / max(1, sum(r["n"] for r in stable)),
        "median_aggregate_tok_s": agg[len(agg) // 2] if agg else 0.0,
    }


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--base-url", default="http://127.0.0.1:8000")
    ap.add_argument("--model", default="nvidia/nemotron-3.5-lightning-30b-a3b")
    ap.add_argument("--levels", default="8,12,16,24,32,48")
    ap.add_argument("--max-tokens", type=int, default=512)
    ap.add_argument("--reps", type=int, default=3)
    ap.add_argument("--timeout", type=float, default=300)
    ap.add_argument("--out", required=True)
    args = ap.parse_args()
    levels = [int(x) for x in args.levels.split(",") if x.strip()]
    out = Path(args.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    report = {
        "ts": datetime.now(timezone.utc).isoformat(),
        "levels": [],
        "stopped_reason": None,
    }
    consec_bad = 0
    for c in levels:
        print(f"=== C{c} ===", flush=True)
        row = run_level(args.base_url, args.model, c, args.max_tokens, args.reps, args.timeout)
        report["levels"].append(row)
        out.write_text(json.dumps(report, indent=2) + "\n")
        print(
            json.dumps(
                {
                    "c": c,
                    "ok_rate": round(row["ok_rate"], 3),
                    "median_agg_tok_s": round(row["median_aggregate_tok_s"], 2),
                }
            ),
            flush=True,
        )
        bad = row["ok_rate"] < 0.75
        consec_bad = consec_bad + 1 if bad else 0
        if consec_bad >= 2:
            report["stopped_reason"] = f"two consecutive bad levels at C{c}"
            break
        mem = None
        try:
            for line in Path("/proc/meminfo").read_text().splitlines():
                if line.startswith("MemAvailable:"):
                    mem = int(line.split()[1]) * 1024
        except Exception:
            pass
        if mem is not None and mem < 8 * 1024**3:
            report["stopped_reason"] = f"MemAvailable={mem} < 8GiB after C{c}"
            break
    else:
        report["stopped_reason"] = "completed all requested levels"
    out.write_text(json.dumps(report, indent=2) + "\n")
    print("DONE", report["stopped_reason"], flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
