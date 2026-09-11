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
ssh -o BatchMode=yes "$host" bash -s -- "$release" <<'REMOTE'
# Container commands below receive no stdin: Compose must not consume this SSH script.
set -euo pipefail
release="$1"
cd "$release"
# Build from the same pinned source and patches on the server. Keeping the
# current image and configuration intact until this succeeds also preserves
# rollback and avoids transferring a multi-gigabyte image over the uplink.
revision="${release##*/}"
image_tag="e22ce197-csim-months-${revision:0:12}"
CSIM_DOCKERFILE=Dockerfile.month-controls CSIM_BUILD_TAG="$image_tag" \
  docker compose -p csim-preview --env-file /home/ubuntu/csim/shared/.env.preview -f compose.yaml build superset
mkdir -p /home/ubuntu/csim/backups
stamp="$(date -u +%Y%m%dT%H%M%S)"
cp /home/ubuntu/csim/shared/.env.preview "/home/ubuntu/csim/backups/preview-$stamp.env"
docker exec csim-preview-superset-1 python -c "import sqlite3; s=sqlite3.connect('/app/superset_home/csim.db'); d=sqlite3.connect('/app/superset_home/before-month-controls.db'); s.backup(d)"
docker cp csim-preview-superset-1:/app/superset_home/before-month-controls.db "/home/ubuntu/csim/backups/preview-$stamp.db"
python3 - "$image_tag" <<'PY'
import sys
from pathlib import Path
p=Path('/home/ubuntu/csim/shared/.env.preview')
values=dict(line.split('=',1) for line in p.read_text().splitlines())
values.update(CSIM_DOCKERFILE='Dockerfile.month-controls',CSIM_BUILD_TAG=sys.argv[1])
p.write_text(''.join(k+'='+v+'\n' for k,v in values.items()))
PY
ln -sfn /home/ubuntu/csim/shared/.env.preview .env.preview
export CSIM_SERVER=1 CSIM_SKIP_BUILD=1
bash csim.sh preview update </dev/null
bash csim.sh preview examples-update </dev/null
bash csim.sh preview simple </dev/null
bash csim.sh preview viewer </dev/null
bash csim.sh preview verify-import </dev/null
bash csim.sh preview pack </dev/null
for profile in simple simple-examples; do
  docker exec csim-preview-superset-1 python /repro/scripts/verify_import.py --profile "$profile"
done
cp output/preview-viewer.json /home/ubuntu/csim/shared/preview-viewer.json
ln -sfn "$release" /home/ubuntu/csim/preview-current
REMOTE
