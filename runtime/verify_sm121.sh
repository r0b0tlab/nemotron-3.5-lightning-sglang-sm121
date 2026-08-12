#!/usr/bin/env bash
set -Eeuo pipefail
IMAGE="${IMAGE:-lmsysorg/sglang:dev-cu13-nemotron3-5-lightning}"
MODEL_CKPT="${MODEL_CKPT:?Set MODEL_CKPT to the local Nemotron Lightning weights directory}"
docker image inspect "$IMAGE" >/dev/null
python3 - <<'PY'
from pathlib import Path
import json, os
root=Path(os.environ['MODEL_CKPT'])
assert (root/'config.json').is_file()
assert (root/'model.safetensors.index.json').is_file()
missing=[f'model-{i:05d}-of-00052.safetensors' for i in range(1,53) if not (root/f'model-{i:05d}-of-00052.safetensors').is_file()]
assert not missing, missing
index=json.loads((root/'model.safetensors.index.json').read_text())
mtp=sum(k.startswith('mtp.') for k in index.get('weight_map',{}))
assert mtp>0
print(f'model_preflight=PASS shards=52 trained_mtp_tensors={mtp}')
PY
echo "image_ok=$IMAGE"
