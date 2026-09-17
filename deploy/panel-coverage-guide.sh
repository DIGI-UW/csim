#!/usr/bin/env bash
# Publish the panel-coverage manual-review pages without touching Superset.
set -euo pipefail
cd "$(dirname "$0")/.."

revision="${1:?Supply a pushed 40-character revision}"
[[ "$revision" =~ ^[0-9a-f]{40}$ ]] || exit 2
git cat-file -e "$revision^{commit}"
[[ -n "$(git branch -r --contains "$revision")" ]] || { echo 'Push the revision first.' >&2; exit 1; }

host="${CSIM_SSH_HOST:-catalyst.openelis-global.org}"
source="/home/ubuntu/csim/panel-coverage-guide/$revision"
site="/home/ubuntu/catalyst-demo/targets/catalyst/runtime/media/csim-design-v2"
release_root="/home/ubuntu/catalyst-demo/targets/catalyst/runtime/media/csim-releases"

ssh -o BatchMode=yes "$host" "mkdir -p '$source'"
git archive "$revision" \
  design/index.html design/filter-guide.html design/beth-review.html \
  design/evidence/panel-coverage | ssh -o BatchMode=yes "$host" "tar -xf - -C '$source'"

ssh -o BatchMode=yes "$host" bash -s -- "$source" "$site" "$release_root" "$revision" <<'REMOTE'
set -euo pipefail
source="$1"; site="$2"; release_root="$3"; revision="$4"
current="$(readlink -f "$site")"
release="$release_root/$revision"
[[ -d "$current" && ! -e "$release" ]]
cp -a "$current" "$release"
cp "$source/design/index.html" "$release/index.html"
cp "$source/design/filter-guide.html" "$release/filter-guide.html"
cp "$source/design/beth-review.html" "$release/beth-review.html"
mkdir -p "$release/evidence/panel-coverage"
cp -a "$source/design/evidence/panel-coverage/." "$release/evidence/panel-coverage/"
python3 - "$release" "$revision" "$current" <<'PY'
import datetime, hashlib, json, sys
from pathlib import Path
release, revision, previous = map(Path, sys.argv[1:])
files = ['index.html', 'filter-guide.html', 'beth-review.html']
files += [str(path.relative_to(release)) for path in sorted((release/'evidence/panel-coverage').iterdir()) if path.is_file()]
receipt = {
  'sourceRevision': str(revision),
  'publishedAt': datetime.datetime.now(datetime.timezone.utc).isoformat(),
  'previousRelease': str(previous),
  'scope': 'Panel coverage and section 4.1 guidance with browser evidence; Superset is unchanged by this publication.',
  'files': [{'path': file, 'sha256': hashlib.sha256((release/file).read_bytes()).hexdigest()} for file in files],
}
(release/'panel-coverage-update.json').write_text(json.dumps(receipt, indent=2)+'\n')
print(json.dumps(receipt))
PY
ln -s "csim-releases/$revision" "$site.pending"
mv -Tf "$site.pending" "$site"
REMOTE
