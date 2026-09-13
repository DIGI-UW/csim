#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

main() {
profile="${1:-corrected}"
action="${2:-status}"
case "$profile" in baseline|corrected|fixture|preview|preview-fixture|standard|development) ;; *) echo 'Unknown CSiM profile.' >&2; exit 2 ;; esac
case "$profile" in corrected) port=18189 ;; baseline) port=18190 ;; fixture) port=18191 ;; preview) port=18192 ;; preview-fixture) port=18193 ;; standard) port=18194 ;; development) port=18195 ;; esac
package_profile="$profile"
[[ "$profile" != fixture ]] || package_profile=corrected
[[ "$profile" != preview-fixture ]] || package_profile=preview
env_file=".env.${profile}"

if [[ ! -f "$env_file" ]]; then
  python3 - "$env_file" "$port" "$profile" <<'PY'
import os, secrets, sys
path, port, profile = sys.argv[1:]
with open(path, 'x', encoding='utf-8') as output:
    for name in ('DB_PASSWORD', 'SECRET_KEY', 'ADMIN_PASSWORD'):
        output.write(f'CSIM_{name}={secrets.token_hex(24)}\n')
    output.write('CSIM_PORT='+port+'\n')
    output.write('CSIM_SUPERSET_IMAGE=apache/superset:6.1.0@sha256:16b50bbef6648912a79e3293d418fefa743ce555d36c5af6b85d859119ed7f88\n')
    output.write('CSIM_APP_ROOT=/\n')
    output.write('CSIM_PUBLIC_URL=http://127.0.0.1:'+port+'\n')
    if profile in ('corrected', 'fixture'):
        output.write('CSIM_DOCKERFILE=Dockerfile.month-controls\nCSIM_BUILD_TAG=6.1.0-csim-september5\n')
    if profile in ('preview','preview-fixture'):
        output.write('CSIM_DOCKERFILE=Dockerfile.month-controls\nCSIM_BUILD_TAG=e22ce197-csim-september7\nCSIM_MONTH_PATCH=superset-snapshot-month-controls.patch\nCSIM_SNAPSHOT=1\n')
        output.write('CSIM_SUPERSET_IMAGE=apache/superset:e22ce197866ded732e4990063ae74697d89d383a-dev@sha256:4abe143d471d0e2b3985b6903a3c2595e0ac94bb9f0c68f5e09934a9ec2a3adb\n')
        output.write('CSIM_SUPERSET_REF=e22ce197866ded732e4990063ae74697d89d383a\nCSIM_PATCH=superset-snapshot-csim-period.patch\nCSIM_NODE_IMAGE=node:24.16.0-bookworm-slim\n')
    if profile == 'standard':
        output.write('CSIM_DOCKERFILE=Dockerfile\nCSIM_BUILD_TAG=6.1.0-standard\n')
    if profile == 'development':
        output.write('CSIM_DOCKERFILE=Dockerfile\nCSIM_BUILD_TAG=e22ce197-standard\nCSIM_SNAPSHOT=1\n')
        output.write('CSIM_SUPERSET_IMAGE=apache/superset:e22ce197866ded732e4990063ae74697d89d383a-dev@sha256:4abe143d471d0e2b3985b6903a3c2595e0ac94bb9f0c68f5e09934a9ec2a3adb\n')
PY
fi

compose() {
  local files=(-f compose.yaml)
  [[ "${CSIM_SERVER:-0}" != 1 ]] || files+=(-f deploy/compose.server.yaml)
  docker compose -p "csim-${profile}" --env-file "$env_file" "${files[@]}" "$@"
}

start() {
  if [[ "${CSIM_SKIP_BUILD:-0}" != 1 ]]; then compose build superset; fi
  compose up -d db
  # Initialize metadata before Gunicorn workers open the new SQLite database.
  # The first public snapshot startup exposed a concurrent WAL setup lock.
  compose stop superset
  compose run -T --rm --no-deps superset superset db upgrade
  compose run -T --rm --no-deps superset superset init
  compose run -T --rm --no-deps superset python /repro/bootstrap_bundle.py
  compose up -d --no-build --wait --wait-timeout 120 superset
}

restore() {
  start
  existing="$(compose exec -T db psql -U csim -d csim_demo -tAc "SELECT to_regnamespace('v1') IS NOT NULL")"
  if [[ "$existing" == 't' ]]; then
    echo 'The demo schema already exists. Use `csim.sh PROFILE reset` before an explicit restore.' >&2
    exit 1
  fi
  role="$(compose exec -T db psql -U csim -d csim_demo -tAc "SELECT 1 FROM pg_roles WHERE rolname = 'postgres'")"
  if [[ "$role" != '1' ]]; then
    # The supplied dump assigns ownership to PostgreSQL's conventional role.
    # This local compatibility role is created in the disposable demo cluster;
    # the source dump itself remains byte-for-byte unchanged.
    compose exec -T db createuser -U csim postgres
  fi
  if [[ "$profile" == *fixture ]]; then
    compose exec -T db psql -v ON_ERROR_STOP=1 -U csim -d csim_demo < data/edge-cases.sql
  else
    compose exec -T db psql -v ON_ERROR_STOP=1 -U csim -d csim_demo < data/v1_schema_dump.sql
  fi
  compose exec -T db psql -v ON_ERROR_STOP=1 -U csim -d csim_demo -c "SELECT COUNT(*) AS hospitals FROM v1.\"CSiM Hospitals and States\";"
}

import_dashboard() {
  compose exec -T superset python /repro/scripts/dashboard_import.py import --profile "$package_profile"
  compose exec -T superset python /repro/scripts/dashboard_import.py receipt --profile "$package_profile"
  mkdir -p output
  compose cp superset:"/tmp/csim-${package_profile}-receipt.json" "output/${profile}-receipt.json"
}

case "$action" in
  init) restore; import_dashboard ;;
  demo-restore) restore ;;
  update) start; import_dashboard ;;
  import) import_dashboard ;;
  examples-init)
    exists="$(compose exec -T db psql -U csim -d csim_demo -tAc "SELECT 1 FROM pg_database WHERE datname = 'csim_fixture'")"
    if [[ "$exists" == 1 ]]; then echo 'Example database already exists; use examples-update for definitions.' >&2; exit 1; fi
    compose exec -T db createdb -U csim csim_fixture
    compose exec -T db psql -v ON_ERROR_STOP=1 -U csim -d csim_fixture < data/edge-cases.sql
    example_profile=examples
    [[ "$profile" != standard && "$profile" != development ]] || example_profile="${profile}-examples"
    compose exec -T superset python /repro/scripts/dashboard_import.py import --profile "$example_profile"
    ;;
  examples-update)
    example_profile=examples
    [[ "$profile" != standard && "$profile" != development ]] || example_profile="${profile}-examples"
    compose exec -T superset python /repro/scripts/dashboard_import.py import --profile "$example_profile"
    ;;
  candidates)
    [[ "$profile" == standard || "$profile" == development ]] || { echo 'Native candidates use standard or development.' >&2; exit 2; }
    exists="$(compose exec -T db psql -U csim -d csim_demo -tAc "SELECT 1 FROM pg_database WHERE datname = 'csim_fixture'")"
    [[ "$exists" == 1 ]] || { echo 'Initialize the separate fixture with examples-init first.' >&2; exit 1; }
    for candidate in "${profile}-sortable" "${profile}-sortable-examples"; do
      compose exec -T superset python /repro/scripts/dashboard_import.py import --profile "$candidate"
      compose exec -T superset python /repro/scripts/verify_import.py --profile "$candidate"
    done
    ;;
  native-months)
    [[ "$profile" == standard ]] || { echo 'Native month selectors currently target official stable Superset.' >&2; exit 2; }
    for candidate in standard-month-selectors standard-month-selectors-examples; do
      compose exec -T superset python /repro/scripts/dashboard_import.py import --profile "$candidate"
      compose exec -T superset python /repro/scripts/verify_import.py --profile "$candidate"
    done
    ;;
  reconciled)
    [[ "$profile" == corrected ]] || { echo 'The September version uses the main instance.' >&2; exit 2; }
    compose exec -T superset python /repro/scripts/reconcile.py
    compose exec -T superset python /repro/demo_access.py
    ;;
  september-months)
    [[ "$profile" == corrected || "$profile" == preview ]] || { echo 'Use a month-controls build with the supplied demo and initialized example database.' >&2; exit 2; }
    for candidate in reconciled-months reconciled-months-examples; do
      compose exec -T superset python /repro/scripts/dashboard_import.py import --profile "$candidate"
      compose exec -T superset python /repro/scripts/verify_import.py --profile "$candidate"
    done
    ;;
  simple)
    [[ "$profile" == preview* ]] || { echo "Month controls require the snapshot build." >&2; exit 2; }
    compose exec -T superset python /repro/scripts/dashboard_import.py import --profile simple
    compose exec -T superset python /repro/scripts/dashboard_import.py import --profile simple-examples
    ;;
  viewer)
    compose exec -T superset python /repro/demo_access.py
    mkdir -p output
    compose cp superset:/app/superset_home/csim-viewer.json "output/${profile}-viewer.json"
    ;;
  hourly)
    compose exec -T superset python /repro/scripts/dashboard_import.py import --profile hourly
    ;;
  test-update)
    compose exec -T superset python /repro/scripts/test_update.py --profile "$package_profile"
    ;;
  verify-import)
    compose exec -T superset python /repro/scripts/verify_import.py --profile "$package_profile"
    mkdir -p output
    compose cp superset:"/tmp/csim-${package_profile}-import-verification.json" "output/${profile}-import-verification.json"
    ;;
  pack)
    compose exec -T superset python /repro/scripts/dashboard_import.py pack --profile "$package_profile"
    mkdir -p output
    compose cp superset:"/tmp/csim-${package_profile}-dashboard.zip" "output/${profile}-dashboard.zip"
    ;;
  config) compose config --quiet ;;
  status) compose ps ;;
  down) compose down ;;
  reset)
    echo "Removing only the csim-${profile} local containers and volumes."
    compose down --volumes
    ;;
  *)
    echo 'Usage: csim.sh {baseline|corrected|fixture|preview} {init|demo-restore|update|verify-import|pack|status|down|reset}' >&2
    exit 2
    ;;
esac
}

main "$@"
