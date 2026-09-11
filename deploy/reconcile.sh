#!/usr/bin/env bash
# Add versioned dashboard assets to the existing main runtime; no rebuild or reseed.
set -euo pipefail
cd "$(dirname "$0")/.."
revision="${1:-$(git rev-parse HEAD)}"
[[ "$revision" =~ ^[0-9a-f]{40}$ ]] || { echo 'Use a full Git revision.' >&2; exit 2; }
host="${CSIM_SSH_HOST:-catalyst.openelis-global.org}"
git fetch origin main
git merge-base --is-ancestor "$revision" origin/main
release="/home/ubuntu/csim/releases/$revision"
ssh -o BatchMode=yes "$host" "mkdir -p '$release'"
git archive "$revision" | ssh -o BatchMode=yes "$host" "tar -xf - -C '$release'"
ssh -o BatchMode=yes "$host" bash -s -- "$release" <<'REMOTE'
set -euo pipefail
release="$1"; revision="${release##*/}"; container=csim-corrected-superset-1
mkdir -p /home/ubuntu/csim/backups
stamp="$(date -u +%Y%m%dT%H%M%S)"
docker exec "$container" python -c "import sqlite3; s=sqlite3.connect('/app/superset_home/csim.db'); d=sqlite3.connect('/app/superset_home/before-reconciliation.db'); s.backup(d)" </dev/null
docker cp "$container:/app/superset_home/before-reconciliation.db" "/home/ubuntu/csim/backups/before-reconciliation-$stamp.db"
target="/tmp/csim-assets-$revision"
docker exec "$container" mkdir -p "$target" </dev/null
for directory in scripts dashboard; do docker cp "$release/$directory" "$container:$target/"; done
docker cp "$release/demo_access.py" "$container:$target/demo_access.py"
docker exec -e CSIM_PROJECT_ROOT="$target" "$container" python "$target/scripts/reconcile.py" </dev/null
docker exec "$container" python "$target/demo_access.py" </dev/null
mkdir -p "$release/output"
for file in reconciliation-verification reconciled-import-verification reconciled-receipt reconciled-examples-import-verification reconciled-examples-receipt; do
  docker cp "$container:/tmp/csim-$file.json" "$release/output/$file.json"
done
for profile in reconciled reconciled-examples; do docker cp "$container:/tmp/csim-$profile-dashboard.zip" "$release/output/$profile-dashboard.zip"; done
docker inspect "$container" --format '{{.Image}}' > "$release/output/runtime-image-id.txt"
printf '%s\n' "$revision" > /home/ubuntu/csim/shared/reconciled-assets-revision
REMOTE
mkdir -p output/reconciled-deployment
rsync -a "$host:$release/output/" output/reconciled-deployment/
