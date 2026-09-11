#!/usr/bin/env bash
# Publish an explicitly requested review candidate without waiting for CI/main.
# The exact revision must already be on a remote branch. Existing data is retained.
set -euo pipefail
cd "$(dirname "$0")/.."
action="${1:?Use stage, activate or assets}"
revision="${2:?Use a full committed revision}"
profile="${3:?Use corrected, standard or development}"
[[ "$revision" =~ ^[0-9a-f]{40}$ ]] || exit 2
case "$profile" in corrected|standard|development) ;; *) exit 2 ;; esac
git cat-file -e "$revision^{commit}"
[[ -n "$(git branch -r --contains "$revision")" ]] || { echo 'Push the exact candidate before publication.' >&2; exit 1; }
host="${CSIM_SSH_HOST:-catalyst.openelis-global.org}"
release="/home/ubuntu/csim/releases/$revision"
if [[ "$action" == stage || "$action" == assets ]]; then
  ssh -o BatchMode=yes "$host" "mkdir -p '$release' /home/ubuntu/csim/shared /home/ubuntu/csim/backups"
  git archive "$revision" | ssh -o BatchMode=yes "$host" "tar -xf - -C '$release'"
elif [[ "$action" != activate ]]; then exit 2; fi
ssh -o BatchMode=yes "$host" bash -s -- "$release" "$profile" "$action" <<'REMOTE'
set -euo pipefail
cd "$1"; profile="$2"; action="$3"; revision="${1##*/}"
shared="/home/ubuntu/csim/shared/.env.$profile"
if [[ "$action" == assets ]]; then
  # Replace only saved definitions in the already running application. This
  # path never starts containers, rebuilds an image or writes reporting data.
  container="csim-$profile-superset-1"
  [[ "$(docker inspect --format '{{.State.Running}}' "$container")" == true ]]
  stamp="$(date -u +%Y%m%dT%H%M%S)"
  backup="/home/ubuntu/csim/backups/$profile-assets-$stamp.db"
  docker exec "$container" python -c "import sqlite3; s=sqlite3.connect('/app/superset_home/csim.db'); d=sqlite3.connect('/app/superset_home/before-assets.db'); s.backup(d)" </dev/null
  docker cp "$container:/app/superset_home/before-assets.db" "$backup"
  target="/tmp/csim-assets-$revision"
  docker exec "$container" mkdir -p "$target" </dev/null
  for directory in dashboard scripts; do docker cp "$1/$directory" "$container:$target/"; done
  if [[ "$profile" == corrected ]]; then
    packages=(reconciled reconciled-examples reconciled-months reconciled-months-examples)
  else
    packages=("$profile" "$profile-examples" "$profile-sortable" "$profile-sortable-examples")
  fi
  for package in "${packages[@]}"; do
    docker exec -e CSIM_PROJECT_ROOT="$target" "$container" python "$target/scripts/dashboard_import.py" import --profile "$package" </dev/null
    docker exec -e CSIM_PROJECT_ROOT="$target" "$container" python "$target/scripts/verify_import.py" --profile "$package" </dev/null
  done
  python3 - "$profile" "$revision" "$backup" "${packages[@]}" <<'PYRECEIPT'
import datetime,json,subprocess,sys
from pathlib import Path
profile,revision,backup,*packages=sys.argv[1:]
receipt={'profile':profile,'assetsRevision':revision,'packages':packages,'rollbackMetadata':backup,
 'runtimeImageId':subprocess.check_output(['docker','inspect','--format','{{.Image}}',f'csim-{profile}-superset-1'],text=True).strip(),
 'updatedAt':datetime.datetime.now(datetime.timezone.utc).isoformat(),'publicVerification':'pending'}
Path(f'/home/ubuntu/csim/shared/{profile}-assets-release.json').write_text(json.dumps(receipt,indent=2)+'\n')
print(json.dumps(receipt))
PYRECEIPT
  exit
fi
if [[ ! -f "$shared" ]]; then
  [[ "$action" == stage && "$profile" != corrected ]] || { echo 'Missing existing main configuration.' >&2; exit 1; }
  bash csim.sh "$profile" config >/dev/null </dev/null
  mv ".env.$profile" "$shared"
fi
ln -sfn "$shared" ".env.$profile"
if [[ "$profile" == corrected ]]; then
  tag="6.1.0-csim-months-${revision:0:12}"; dockerfile=Dockerfile.month-controls
else
  tag="$profile-${revision:0:12}"; dockerfile=Dockerfile
fi
if [[ "$action" == stage ]]; then
  CSIM_DOCKERFILE="$dockerfile" CSIM_BUILD_TAG="$tag" CSIM_MONTH_PATCH=superset-6.1.0-month-controls.patch \
    docker compose -p "csim-$profile" --env-file "$shared" -f compose.yaml build superset </dev/null
  exit
fi
docker image inspect "csim-superset:$tag" >/dev/null
stamp="$(date -u +%Y%m%dT%H%M%S)"
backup="/home/ubuntu/csim/backups/$profile-$stamp"
cp "$shared" "$backup.env"
if docker inspect "csim-$profile-superset-1" >/dev/null 2>&1; then
  docker inspect "csim-$profile-superset-1" --format '{{.Image}} {{.Config.Image}}' > "$backup.image"
  docker exec "csim-$profile-superset-1" python -c "import sqlite3; s=sqlite3.connect('/app/superset_home/csim.db'); d=sqlite3.connect('/app/superset_home/before-update.db'); s.backup(d)" </dev/null
  docker cp "csim-$profile-superset-1:/app/superset_home/before-update.db" "$backup.db"
fi
python3 - "$shared" "$profile" "$tag" "$dockerfile" <<'PY'
from pathlib import Path
import sys
p=Path(sys.argv[1]); profile=sys.argv[2]
values=dict(line.split('=',1) for line in p.read_text().splitlines())
host={'corrected':'dashboard','standard':'standard','development':'upstream'}[profile]
alias={'corrected':'csim-main-v2','standard':'csim-standard','development':'csim-development'}[profile]
values.update(CSIM_BUILD_TAG=sys.argv[3],CSIM_DOCKERFILE=sys.argv[4],
 CSIM_MONTH_PATCH='superset-6.1.0-month-controls.patch',CSIM_APP_ROOT='/',
 CSIM_PUBLIC_URL='https://'+host+'.csim.uwdigi.org',CSIM_PUBLIC_HTTPS='1',
 CSIM_PROXY_ALIAS=alias,CSIM_OVERVIEW_URL='https://design.csim.uwdigi.org/')
p.write_text(''.join(k+'='+v+'\n' for k,v in values.items()));p.chmod(0o600)
PY
export CSIM_SERVER=1 CSIM_SKIP_BUILD=1
if [[ "$profile" == corrected ]]; then
  bash csim.sh corrected update </dev/null
  bash csim.sh corrected reconciled </dev/null
  bash csim.sh corrected september-months </dev/null
else
  # Compose names volumes from the project, including its hyphen.
  existing="$(docker volume ls -q --filter "name=^csim-${profile}_warehouse$")"
  if [[ -z "$existing" ]]; then
    bash csim.sh "$profile" init </dev/null
    bash csim.sh "$profile" examples-init </dev/null
  else
    bash csim.sh "$profile" update </dev/null
    bash csim.sh "$profile" examples-update </dev/null
  fi
  bash csim.sh "$profile" candidates </dev/null
  python3 scripts/verify_standard_assets.py "$profile" </dev/null
fi
bash csim.sh "$profile" viewer </dev/null
cp "output/$profile-viewer.json" "/home/ubuntu/csim/shared/$profile-viewer.json"
python3 - "$profile" "$revision" "$backup" <<'PY'
import json,sys,subprocess,datetime
from pathlib import Path
profile,revision,backup=sys.argv[1:]
receipt={'profile':profile,'revision':revision,'status':'review candidate; public browser verification pending',
 'imageId':subprocess.check_output(['docker','inspect','--format','{{.Image}}',f'csim-{profile}-superset-1'],text=True).strip(),
 'rollbackPrefix':backup,'activatedAt':datetime.datetime.now(datetime.timezone.utc).isoformat()}
Path(f'/home/ubuntu/csim/shared/{profile}-review-release.json').write_text(json.dumps(receipt,indent=2)+'\n')
print(json.dumps(receipt))
PY
ln -sfn "$1" "/home/ubuntu/csim/$profile-current"
REMOTE
