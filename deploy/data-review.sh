#!/usr/bin/env bash
# Add the isolated Data & records assets during Beth's reporting-dashboard review.
# This does not activate images or import any reporting-dashboard definitions.
set -euo pipefail
cd "$(dirname "$0")/.."
revision="${1:?Supply a pushed commit revision}"
[[ "$revision" =~ ^[0-9a-f]{40}$ ]] || exit 2
git cat-file -e "$revision^{commit}"
[[ -n "$(git branch -r --contains "$revision")" ]] || { echo 'Push the tested revision first.' >&2; exit 1; }
host="${CSIM_SSH_HOST:-catalyst.openelis-global.org}"
target="/home/ubuntu/csim/data-review/$revision"
ssh -o BatchMode=yes "$host" "mkdir -p '$target'"
git archive "$revision" review scripts/install_data_review.py scripts/dashboard_import.py scripts/test_record_review.py |
  ssh -o BatchMode=yes "$host" "tar -xf - -C '$target'"
ssh -o BatchMode=yes "$host" bash -s -- "$target" "$revision" <<'REMOTE'
set -euo pipefail
source="$1"; revision="$2"; container=csim-standard-superset-1; runtime="/tmp/csim-data-review-$revision"
[[ "$(docker inspect --format '{{.State.Running}}' "$container")" == true ]]
docker exec "$container" python -c "import sqlite3; s=sqlite3.connect('/app/superset_home/csim.db'); d=sqlite3.connect('/app/superset_home/before-data-review-$revision.db'); s.backup(d)"
docker exec "$container" mkdir -p "$runtime"
docker cp "$source/review" "$container:$runtime/"
docker cp "$source/scripts" "$container:$runtime/"
docker exec -e CSIM_PROJECT_ROOT="$runtime" "$container" python "$runtime/scripts/install_data_review.py" --apply --output "/app/superset_home/data-review-$revision.json"
docker exec -e CSIM_PROJECT_ROOT="$runtime" "$container" python "$runtime/scripts/test_record_review.py"
docker cp "$container:/app/superset_home/data-review-$revision.json" "$source/receipt.json"
REMOTE
