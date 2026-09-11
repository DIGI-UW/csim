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
      # Build the pinned source on the server; keep its running images intact.
      ssh -o BatchMode=yes "$host" bash -s -- "$release" <<'REMOTE'
set -euo pipefail
cd "$1"
revision="${1##*/}"
for profile in corrected preview; do
  dockerfile=Dockerfile.formatter; prefix=6.1.0-csim
  if [[ "$profile" == preview ]]; then dockerfile=Dockerfile.month-controls; prefix=e22ce197-csim-months; fi
  env_file="/home/ubuntu/csim/shared/.env.$profile"
  if [[ ! -f "$env_file" ]]; then
    bash csim.sh "$profile" config >/dev/null </dev/null
    env_file=".env.$profile"
  fi
  CSIM_DOCKERFILE="$dockerfile" CSIM_BUILD_TAG="$prefix-${revision:0:12}" \
    docker compose -p "csim-$profile" --env-file "$env_file" -f compose.yaml build superset </dev/null
done
REMOTE
      ;;
    init|update)
      ssh -o BatchMode=yes "$host" bash -s -- "$release" "$action" <<'REMOTE'
# Container commands below receive no stdin: Compose must not consume this SSH script.
set -euo pipefail
release="$1"; action="$2"
cd "$release"
for profile in corrected preview; do
  shared="/home/ubuntu/csim/shared/.env.$profile"
  if [[ ! -f "$shared" ]]; then
    [[ "$action" == init ]] || { echo 'Missing instance configuration.' >&2; exit 1; }
    # config creates credentials without starting or restoring a service.
    bash csim.sh "$profile" config >/dev/null </dev/null
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
    stamp="$(date -u +%Y%m%dT%H%M%S)"
    cp "$shared" "/home/ubuntu/csim/backups/$profile-$stamp.env"
    docker exec "csim-$profile-superset-1" python -c "import sqlite3; s=sqlite3.connect('/app/superset_home/csim.db'); d=sqlite3.connect('/app/superset_home/before-update.db'); s.backup(d)"
    docker cp "csim-$profile-superset-1:/app/superset_home/before-update.db" "/home/ubuntu/csim/backups/$profile-$stamp.db"
  fi
  revision="${release##*/}"
  prefix=6.1.0-csim; dockerfile=Dockerfile.formatter
  if [[ "$profile" == preview ]]; then prefix=e22ce197-csim-months; dockerfile=Dockerfile.month-controls; fi
  image_tag="$prefix-${revision:0:12}"
  docker image inspect "csim-superset:$image_tag" >/dev/null
  python3 - "$shared" "$image_tag" "$dockerfile" <<'PY'
import sys
from pathlib import Path
p=Path(sys.argv[1]); values=dict(line.split('=',1) for line in p.read_text().splitlines())
values.update(CSIM_BUILD_TAG=sys.argv[2],CSIM_DOCKERFILE=sys.argv[3])
p.write_text(''.join(k+'='+v+'\n' for k,v in values.items()))
PY
  CSIM_SERVER=1 CSIM_SKIP_BUILD=1 bash csim.sh "$profile" "$action" </dev/null
  if [[ "$action" == init ]]; then example_action=examples-init; else example_action=examples-update; fi
  CSIM_SERVER=1 bash csim.sh "$profile" "$example_action" </dev/null
  if [[ "$profile" == preview ]]; then
    CSIM_SERVER=1 bash csim.sh preview hourly </dev/null
    CSIM_SERVER=1 bash csim.sh preview simple </dev/null
  fi
  if [[ "$profile" == corrected ]]; then CSIM_SERVER=1 bash csim.sh corrected reconciled </dev/null; fi
  CSIM_SERVER=1 bash csim.sh "$profile" viewer </dev/null
  CSIM_SERVER=1 bash csim.sh "$profile" verify-import </dev/null
  CSIM_SERVER=1 bash csim.sh "$profile" pack </dev/null
  CSIM_SERVER=1 bash csim.sh "$profile" test-update </dev/null
  CSIM_SERVER=1 bash csim.sh "$profile" verify-import </dev/null
  cp "output/$profile-viewer.json" "/home/ubuntu/csim/shared/$profile-viewer.json"
done
ln -sfn "$release" /home/ubuntu/csim/current
ln -sfn "$release" /home/ubuntu/csim/preview-current
REMOTE
      ;;
    hosts|redirects)
      ssh -o BatchMode=yes "$host" bash -s -- "$release" "$action" <<'REMOTE'
# Container commands below receive no stdin: Compose must not consume this SSH script.
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
