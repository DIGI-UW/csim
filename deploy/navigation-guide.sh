#!/usr/bin/env bash
# Publish approved dashboard guidance and selected guide pages without a full import.
set -euo pipefail
cd "$(dirname "$0")/.."
revision="${1:?Supply a pushed commit revision}"
[[ "$revision" =~ ^[0-9a-f]{40}$ ]] || exit 2
git cat-file -e "$revision^{commit}"
[[ -n "$(git branch -r --contains "$revision")" ]] || { echo 'Push the tested revision first.' >&2; exit 1; }
host="${CSIM_SSH_HOST:-catalyst.openelis-global.org}"
target="/home/ubuntu/csim/navigation-guide/$revision"
ssh -o BatchMode=yes -o ConnectTimeout=15 "$host" "mkdir -p '$target'"
git archive "$revision" scripts/update_navigation.py scripts/capture_live_review.py scripts/dashboard_import.py \
  dashboard/standard-month-selectors/dashboards design/index.html design/beth-review.html design/filter-guide.html \
  design/evidence/beth-review/therapy-filter-mismatch.png |
  ssh -o BatchMode=yes "$host" "tar -xf - -C '$target'"
ssh -o BatchMode=yes "$host" bash -s -- "$target" "$revision" <<'REMOTE'
set -euo pipefail
source="$1"; revision="$2"; container=csim-standard-superset-1
runtime="/tmp/csim-navigation-$revision"
site=/home/ubuntu/catalyst-demo/targets/catalyst/runtime/media/csim-design-v2
[[ -d "$site" && "$(docker inspect --format '{{.State.Running}}' "$container")" == true ]]
[[ ! -e "$source/receipt.json" ]] || { echo 'This revision already has a deployment receipt.' >&2; exit 1; }
# A consistent SQLite backup is available in addition to the field-level rollback.
docker exec "$container" python -c "import sqlite3; s=sqlite3.connect('/app/superset_home/csim.db'); d=sqlite3.connect('/app/superset_home/before-navigation-$revision.db'); s.backup(d)"
docker exec "$container" mkdir -p "$runtime"
docker cp "$source/scripts" "$container:$runtime/"
docker cp "$source/dashboard" "$container:$runtime/"
docker exec "$container" python "$runtime/scripts/update_navigation.py" \
  --definition "$runtime/dashboard/standard-month-selectors/dashboards/CSiM_UTI_ASB_Dashboard_Individual_Data_11.yaml" \
  --output "/app/superset_home/navigation-$revision.json" --apply
docker cp "$container:/app/superset_home/navigation-$revision.json" "$source/receipt.json"
python3 - "$source" "$site" "$revision" <<'PY'
import datetime, hashlib, json, os, shutil, sys
from pathlib import Path
source, site = map(Path, sys.argv[1:3]); revision = sys.argv[3]
paths = ['evidence/beth-review/therapy-filter-mismatch.png', 'filter-guide.html', 'beth-review.html', 'index.html']
backup = source / 'previous-site'; backup.mkdir(exist_ok=True)
files = []
for name in paths:
    dest = site / name; src = source / 'design' / name
    if dest.exists():
        previous = backup / name; previous.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(dest, previous)
    dest.parent.mkdir(parents=True, exist_ok=True)
    pending = dest.with_name(dest.name + '.pending-' + revision[:8])
    shutil.copy2(src, pending); os.replace(pending, dest)
    files.append({'path':name, 'sha256':hashlib.sha256(dest.read_bytes()).hexdigest()})
receipt = json.loads((source / 'receipt.json').read_text())
public = {'sourceRevision':revision, 'publishedAt':datetime.datetime.now(datetime.timezone.utc).isoformat(),
          'scope':'Guide pages, sidebar headings, hospital guidance and nested Table of Contents',
          'dashboardSlug':receipt['slug'], 'chartCount':receipt['chartCount'],
          'actualFiltersUnchanged':receipt['actualFiltersUnchanged'],
          'reportingDefinitionsUnchanged':receipt['reportingDefinitionsUnchanged'], 'files':files}
(site / 'guide-update.json').write_text(json.dumps(public, indent=2)+'\n')
(source / 'publication.json').write_text(json.dumps(public, indent=2)+'\n')
print(json.dumps(public))
PY
REMOTE
