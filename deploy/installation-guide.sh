#!/usr/bin/env bash
# Publish the client installation guide and its tested definition-only package.
set -euo pipefail
cd "$(dirname "$0")/.."

revision="${1:?Supply a pushed 40-character revision}"
[[ "$revision" =~ ^[0-9a-f]{40}$ ]] || exit 2
git cat-file -e "$revision^{commit}"
[[ -n "$(git branch -r --contains "$revision")" ]] || { echo 'Push the revision first.' >&2; exit 1; }

host="${CSIM_SSH_HOST:-catalyst.openelis-global.org}"
source="/home/ubuntu/csim/installation-guide/$revision"
site="/home/ubuntu/catalyst-demo/targets/catalyst/runtime/media/csim-design-v2"
release_root="/home/ubuntu/catalyst-demo/targets/catalyst/runtime/media/csim-releases"

ssh -o BatchMode=yes "$host" "mkdir -p '$source'"
git archive "$revision" \
  design/index.html design/review.html design/filter-guide.html design/data-guide.html design/install.html \
  release/client-update/csim-client-update-dashboard.zip release/client-update/SHA256SUMS \
  release/client-update/manual/01-csim-reporting-datasets.zip \
  release/client-update/manual/02-csim-dashboard-charts.zip \
  release/client-update/manual/03-csim-dashboard.zip \
  release/client-update/manual/README.md release/client-update/manual/SHA256SUMS \
  release/client-update/rehearsal.json release/client-update/baseline-comparison.json |
  ssh -o BatchMode=yes "$host" "tar -xf - -C '$source'"

ssh -o BatchMode=yes "$host" bash -s -- "$source" "$site" "$release_root" "$revision" <<'REMOTE'
set -euo pipefail
source="$1"; site="$2"; release_root="$3"; revision="$4"
current="$(readlink -f "$site")"
release="$release_root/$revision"
[[ -d "$current" && ! -e "$release" ]]
cp -a "$current" "$release"
for file in index.html review.html filter-guide.html data-guide.html install.html; do
  cp "$source/design/$file" "$release/$file"
done
mkdir -p "$release/downloads"
cp "$source/release/client-update/csim-client-update-dashboard.zip" "$release/downloads/"
cp "$source/release/client-update/SHA256SUMS" "$release/downloads/client-update-SHA256SUMS"
cp "$source/release/client-update/manual/01-csim-reporting-datasets.zip" "$release/downloads/"
cp "$source/release/client-update/manual/02-csim-dashboard-charts.zip" "$release/downloads/"
cp "$source/release/client-update/manual/03-csim-dashboard.zip" "$release/downloads/"
cp "$source/release/client-update/manual/README.md" "$release/downloads/manual-installation.txt"
cp "$source/release/client-update/manual/SHA256SUMS" "$release/downloads/manual-SHA256SUMS"
cp "$source/release/client-update/rehearsal.json" "$release/downloads/client-update-rehearsal.json"
cp "$source/release/client-update/baseline-comparison.json" "$release/downloads/client-update-baseline-comparison.json"
python3 - "$release" "$revision" "$current" <<'PY'
import datetime, hashlib, json, sys
from pathlib import Path
release, revision, previous = map(Path, sys.argv[1:])
files = ['index.html','review.html','filter-guide.html','data-guide.html','install.html',
         'downloads/csim-client-update-dashboard.zip','downloads/client-update-SHA256SUMS',
         'downloads/01-csim-reporting-datasets.zip','downloads/02-csim-dashboard-charts.zip',
         'downloads/03-csim-dashboard.zip','downloads/manual-installation.txt','downloads/manual-SHA256SUMS',
         'downloads/client-update-rehearsal.json','downloads/client-update-baseline-comparison.json']
receipt = {
  'sourceRevision': str(revision),
  'publishedAt': datetime.datetime.now(datetime.timezone.utc).isoformat(),
  'previousRelease': str(previous),
  'scope': 'Client installation guide and the tested definition-only CSiM update package; Superset and reporting data are unchanged.',
  'files': [{'path': file, 'sha256': hashlib.sha256((release/file).read_bytes()).hexdigest()} for file in files],
}
(release/'installation-guide-update.json').write_text(json.dumps(receipt,indent=2)+'\n')
print(json.dumps(receipt))
PY
ln -s "csim-releases/$revision" "$site.pending"
mv -Tf "$site.pending" "$site"
REMOTE
