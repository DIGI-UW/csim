#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
revision="${1:?Supply the tested full Git revision}"
[[ "$revision" =~ ^[0-9a-f]{40}$ ]] || exit 2
host="${CSIM_SSH_HOST:-catalyst.openelis-global.org}"
release="/home/ubuntu/csim/releases/$revision"
git fetch origin main
git merge-base --is-ancestor "$revision" origin/main
ssh -o BatchMode=yes "$host" "mkdir -p '$release'"
git archive "$revision" | ssh -o BatchMode=yes "$host" "tar -xf - -C '$release'"
docker save csim-superset:e22ce197-csim-months-1 | gzip | ssh -o BatchMode=yes "$host" 'gunzip | docker load'
ssh -o BatchMode=yes "$host" bash -s -- "$release" <<'REMOTE'
set -euo pipefail
release="$1"
cd "$release"
mkdir -p /home/ubuntu/csim/backups
stamp="$(date -u +%Y%m%dT%H%M%S)"
cp /home/ubuntu/csim/shared/.env.preview "/home/ubuntu/csim/backups/preview-$stamp.env"
docker exec csim-preview-superset-1 python -c "import sqlite3; s=sqlite3.connect('/app/superset_home/csim.db'); d=sqlite3.connect('/app/superset_home/before-month-controls.db'); s.backup(d)"
docker cp csim-preview-superset-1:/app/superset_home/before-month-controls.db "/home/ubuntu/csim/backups/preview-$stamp.db"
python3 - <<'PY'
from pathlib import Path
p=Path('/home/ubuntu/csim/shared/.env.preview')
values=dict(line.split('=',1) for line in p.read_text().splitlines())
values.update(CSIM_DOCKERFILE='Dockerfile.month-controls',CSIM_BUILD_TAG='e22ce197-csim-months-1')
p.write_text(''.join(k+'='+v+'\n' for k,v in values.items()))
PY
ln -sfn /home/ubuntu/csim/shared/.env.preview .env.preview
export CSIM_SERVER=1 CSIM_SKIP_BUILD=1
bash csim.sh preview update
bash csim.sh preview examples-update
bash csim.sh preview simple
bash csim.sh preview viewer
bash csim.sh preview verify-import
bash csim.sh preview pack
for profile in simple simple-examples; do
  docker exec csim-preview-superset-1 python /repro/scripts/verify_import.py --profile "$profile"
done
cp output/preview-viewer.json /home/ubuntu/csim/shared/preview-viewer.json
ln -sfn "$release" /home/ubuntu/csim/preview-current
REMOTE
