#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
main() {
  action="${1:?Use stage, init, update, hosts, or redirects}"
  revision="${2:-$(git rev-parse HEAD)}"
  [[ "$revision" =~ ^[0-9a-f]{40}$ ]] || { echo 'Use a full tested Git revision.' >&2; exit 2; }
  host="${CSIM_SSH_HOST:-catalyst.openelis-global.org}"
  release="/home/ubuntu/csim/releases/$revision"
  case "$action" in
    stage)
      git fetch origin main
      git merge-base --is-ancestor "$revision" origin/main
      ssh -o BatchMode=yes "$host" "mkdir -p '$release' /home/ubuntu/csim/shared"
      git archive "$revision" | ssh -o BatchMode=yes "$host" "tar -xf - -C '$release'"
      # The server and tested local images are both ARM64. Stream the image
      # layers directly; do not leave another large archive on the server.
      docker save csim-superset:6.1.0-csim-1 csim-superset:e22ce197-csim-1 | gzip | ssh -o BatchMode=yes "$host" 'gunzip | docker load'
      ;;
    init|update)
      ssh -o BatchMode=yes "$host" bash -s -- "$release" "$action" <<'REMOTE'
set -euo pipefail
release="$1"; action="$2"
cd "$release"
for profile in corrected preview; do
  shared="/home/ubuntu/csim/shared/.env.$profile"
  if [[ ! -f "$shared" ]]; then
    [[ "$action" == init ]] || { echo 'Missing instance configuration.' >&2; exit 1; }
    # config creates credentials without starting or restoring a service.
    bash csim.sh "$profile" config >/dev/null
    mv ".env.$profile" "$shared"
    python3 - "$shared" "$profile" <<'PY'
import sys
from pathlib import Path
p=Path(sys.argv[1]);profile=sys.argv[2]
lines=dict(line.split('=',1) for line in p.read_text().splitlines())
lines.update(CSIM_PUBLIC_URL='https://'+('preview' if profile=='preview' else 'dashboard')+'.csim.uwdigi.org',CSIM_PUBLIC_HTTPS='1',CSIM_APP_ROOT='/',CSIM_PROXY_ALIAS='csim-preview-v2' if profile=='preview' else 'csim-main-v2',CSIM_OVERVIEW_URL='https://design.csim.uwdigi.org/')
p.write_text(''.join(k+'='+v+'\n' for k,v in lines.items()));p.chmod(0o600)
PY
  fi
  ln -sfn "$shared" ".env.$profile"
  if [[ "$action" == update ]]; then
    mkdir -p /home/ubuntu/csim/backups
    docker exec "csim-$profile-superset-1" python -c "import sqlite3; s=sqlite3.connect('/app/superset_home/csim.db'); d=sqlite3.connect('/app/superset_home/before-update.db'); s.backup(d)"
    docker cp "csim-$profile-superset-1:/app/superset_home/before-update.db" "/home/ubuntu/csim/backups/$profile-$(date -u +%Y%m%dT%H%M%S).db"
  fi
  CSIM_SERVER=1 CSIM_SKIP_BUILD=1 bash csim.sh "$profile" "$action"
  if [[ "$action" == init ]]; then example_action=examples-init; else example_action=examples-update; fi
  CSIM_SERVER=1 bash csim.sh "$profile" "$example_action"
  if [[ "$profile" == preview ]]; then CSIM_SERVER=1 bash csim.sh preview hourly; fi
  CSIM_SERVER=1 bash csim.sh "$profile" viewer
  CSIM_SERVER=1 bash csim.sh "$profile" verify-import
  CSIM_SERVER=1 bash csim.sh "$profile" pack
  CSIM_SERVER=1 bash csim.sh "$profile" test-update
  CSIM_SERVER=1 bash csim.sh "$profile" verify-import
  cp "output/$profile-viewer.json" "/home/ubuntu/csim/shared/$profile-viewer.json"
done
ln -sfn "$release" /home/ubuntu/csim/current
REMOTE
      ;;
    hosts|redirects)
      ssh -o BatchMode=yes "$host" bash -s -- "$release" "$action" <<'REMOTE'
set -euo pipefail
release="$1"; action="$2"
config=/home/ubuntu/catalyst-demo/targets/catalyst/Caddyfile
backup="/home/ubuntu/csim/shared/Caddyfile-$(date -u +%Y%m%dT%H%M%S)"
cp "$config" "$backup"
extra=(); [[ "$action" != redirects ]] || extra+=(--redirects)
python3 "$release/deploy/render_caddy.py" "$config" /tmp/csim-Caddyfile "${extra[@]}"
docker cp /tmp/csim-Caddyfile catalyst-demo-caddy-1:/tmp/csim-Caddyfile
docker exec catalyst-demo-caddy-1 caddy validate --config /tmp/csim-Caddyfile --adapter caddyfile
# Caddy's admin API is disabled in the existing deployment. Keep the bind
# mount inode and restart the proxy only after configuration validation.
cat /tmp/csim-Caddyfile > "$config"
if ! docker restart catalyst-demo-caddy-1; then cat "$backup" > "$config"; docker restart catalyst-demo-caddy-1; exit 1; fi
printf '%s\n' "$backup" > /home/ubuntu/csim/shared/last-proxy-backup
REMOTE
      ;;
    *) echo 'Use stage, init, update, hosts, or redirects.' >&2; exit 2 ;;
  esac
}
main "$@"
