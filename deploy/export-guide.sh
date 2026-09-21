#!/usr/bin/env bash
# Publish only the verified record-export guide, video and upload-source guidance.
set -euo pipefail
cd "$(dirname "$0")/.."
revision="${1:?Supply a pushed 40-character revision}"
[[ "$revision" =~ ^[0-9a-f]{40}$ ]] || exit 2
git cat-file -e "$revision^{commit}"
[[ -n "$(git branch -r --contains "$revision")" ]] || { echo 'Push the revision first.' >&2; exit 1; }
host="${CSIM_SSH_HOST:-catalyst.openelis-global.org}"
source="/home/ubuntu/csim/export-guide/$revision"
site="/home/ubuntu/catalyst-demo/targets/catalyst/runtime/media/csim-design-v2"
release_root="/home/ubuntu/catalyst-demo/targets/catalyst/runtime/media/csim-releases"
ssh -o BatchMode=yes "$host" "mkdir -p '$source'"
git archive "$revision" design/record-export.html design/data-guide.html design/evidence/record-export |
  ssh -o BatchMode=yes "$host" "tar -xf - -C '$source'"
ssh -o BatchMode=yes "$host" bash -s -- "$source" "$site" "$release_root" "$revision" <<'REMOTE'
set -euo pipefail
source="$1"; site="$2"; release_root="$3"; revision="$4"
current="$(readlink -f "$site")"
release="$release_root/$revision"
[[ -d "$current" && ! -e "$release" ]]
cp -a "$current" "$release"
cp "$source/design/record-export.html" "$source/design/data-guide.html" "$release/"
mkdir -p "$release/evidence/record-export"
cp -a "$source/design/evidence/record-export/." "$release/evidence/record-export/"
python3 - "$release" "$revision" "$current" <<'PY'
import datetime, hashlib, json, sys
from pathlib import Path
release, revision, previous = Path(sys.argv[1]), sys.argv[2], sys.argv[3]
files = ['record-export.html', 'data-guide.html'] + [str(p.relative_to(release)) for p in sorted((release/'evidence/record-export').rglob('*')) if p.is_file()]
receipt = {'sourceRevision':revision,'publishedAt':datetime.datetime.now(datetime.timezone.utc).isoformat(),
 'previousRelease':previous,'scope':'Record CSV demonstration and source-table guidance; no Superset or data changes.',
 'files':[{'path':f,'sha256':hashlib.sha256((release/f).read_bytes()).hexdigest()} for f in files]}
(release/'export-guide-update.json').write_text(json.dumps(receipt,indent=2)+'\n')
print(json.dumps(receipt))
PY
ln -s "csim-releases/$revision" "$site.pending"
mv -Tf "$site.pending" "$site"
REMOTE
