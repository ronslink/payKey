#!/usr/bin/env bash
# The GitHub production environment authorizes this release script. Do not run
# it for an audit: it deliberately replaces services.
set -Eeuo pipefail
umask 077

release_dir=$(realpath -e "${1:?Pass the staged release directory}")
case "$release_dir" in /opt/paykey/releases/*) ;; *) echo 'Release must be staged under /opt/paykey/releases'; exit 1 ;; esac
release_id=$(basename "$release_dir")
[[ "$release_id" =~ ^[a-f0-9]{40}-[0-9]+-[0-9]+$ ]] || { echo 'Invalid release directory identifier'; exit 1; }
project="paykey-${release_id}"
candidate="$release_dir/.env.candidate"
[[ -f "$candidate" && ! -L "$candidate" ]] || { echo 'A regular candidate environment file is required'; exit 1; }
[[ -s /opt/paykey/ca-certificate.crt && -f /opt/paykey/ca-certificate.crt ]] || { echo 'Install the managed database CA certificate before release'; exit 1; }
chmod 600 "$candidate"
backend=(docker compose -p "$project" --env-file "$candidate" -f "$release_dir/deploy/docker-compose.backend.yml")
infra=(docker compose -p "$project" --env-file "$candidate" -f "$release_dir/deploy/docker-compose.infra.yml")

# Candidate validation/pull/read-only audit happen before stopping the old app.
docker info >/dev/null
docker compose version >/dev/null
"${backend[@]}" config --quiet
"${infra[@]}" config --quiet
available_kb=$(df -Pk /opt/paykey | awk 'NR==2 {print $4}')
[[ "$available_kb" -ge 1048576 ]] || { echo 'At least 1 GiB free disk is required; no rollback images will be pruned'; exit 1; }
if ! docker network inspect paykey-network-prod >/dev/null 2>&1; then
  docker network create paykey-network-prod >/dev/null
fi
"${backend[@]}" pull backend
"${infra[@]}" pull redis

# The image runs as node (uid/gid 1000). Prepare only its dedicated data paths;
# do not change the live container, source uploads, or retained rollback copies.
for directory in /opt/paykey/storage /opt/paykey/legacy-uploads /opt/paykey/secrets; do
  [[ ! -L "$directory" ]] || { echo 'Application data directories must not be symlinks'; exit 1; }
  mkdir -p "$directory"
done
chown -hR 1000:1000 /opt/paykey/storage
chmod 700 /opt/paykey/storage
firebase_file=/opt/paykey/secrets/firebase-service-account.json
if [[ -e "$firebase_file" || -L "$firebase_file" ]]; then
  [[ -f "$firebase_file" && ! -L "$firebase_file" ]] || { echo 'Firebase credentials must be a regular file'; exit 1; }
  chgrp 1000 /opt/paykey/secrets "$firebase_file"
  chmod 750 /opt/paykey/secrets
  chmod 640 "$firebase_file"
fi
"${backend[@]}" run --rm --no-deps backend node scripts/audit-production.cjs --configuration-only
# This launch introduces no migrations. Refuse every pending legacy migration
# before stopping writers: old scripts may destroy data or assume prior schema
# synchronization. Any required SQL needs a separate reviewed/rehearsed step.
"${backend[@]}" run --rm --no-deps backend node scripts/audit-production.cjs --require-migrations-current

old_backend=""
old_redis=""
has_uploads=false
has_exports=false
backend_was_running=false
redis_was_running=false
rollback_needed=false
environment_promoted=false
if [[ -f /opt/paykey/.env ]]; then
  cp /opt/paykey/.env "$release_dir/previous.env"
  chmod 600 "$release_dir/previous.env"
fi
if docker container inspect paykey_backend_prod >/dev/null 2>&1; then
  [[ $(docker inspect --format '{{.State.Running}}' paykey_backend_prod) == true ]] || { echo 'Existing backend is stopped; recover or inspect it before releasing'; exit 1; }
  backend_was_running=true
  has_uploads=$(docker exec paykey_backend_prod node -e 'process.stdout.write(String(require("fs").existsSync("/app/uploads")))')
  [[ "$has_uploads" == true || "$has_uploads" == false ]] || { echo 'Cannot determine legacy upload state'; exit 1; }
  has_exports=$(docker exec paykey_backend_prod node -e 'process.stdout.write(String(require("fs").existsSync("/app/exports")))')
  [[ "$has_exports" == true || "$has_exports" == false ]] || { echo 'Cannot determine legacy export state'; exit 1; }
  docker inspect --format '{{.Image}}' paykey_backend_prod > "$release_dir/previous-backend-image.txt"
fi
if docker container inspect paykey_redis_prod >/dev/null 2>&1; then
  [[ $(docker inspect --format '{{.State.Running}}' paykey_redis_prod) == true ]] || { echo 'Existing Redis is stopped; recover it before releasing'; exit 1; }
  redis_was_running=true
  REDIS_DATA_VOLUME=$(docker inspect --format '{{range .Mounts}}{{if and (eq .Destination "/data") (eq .Type "volume")}}{{.Name}}{{end}}{{end}}' paykey_redis_prod)
  [[ "$REDIS_DATA_VOLUME" =~ ^[a-zA-Z0-9][a-zA-Z0-9_.-]+$ ]] || { echo 'Existing Redis must have a persistent named /data volume'; exit 1; }
  export REDIS_DATA_VOLUME
  printf '%s\n' "$REDIS_DATA_VOLUME" > "$release_dir/redis-volume.txt"
fi
REDIS_DATA_VOLUME=${REDIS_DATA_VOLUME:-paykey_redis_data_prod}
export REDIS_DATA_VOLUME
# Persist the discovered volume name so later operations cannot silently select
# an empty volume under a different Compose project name.
printf "REDIS_DATA_VOLUME='%s'\n" "$REDIS_DATA_VOLUME" >> "$candidate"
"${infra[@]}" config --quiet

remove_new_container() {
  local name=$1
  if [[ $(docker inspect --format '{{index .Config.Labels "com.docker.compose.project"}}' "$name" 2>/dev/null || true) == "$project" ]]; then
    docker rm -f "$name" >/dev/null
  fi
}
rollback() {
  local status=$?
  if [[ "$status" -eq 0 ]]; then status=1; fi
  trap - ERR INT TERM
  set +e
  if [[ "$rollback_needed" == true ]]; then
    echo 'Release failed. Restoring retained application/Redis containers; database migrations are not automatically reversed.'
    remove_new_container paykey_backend_prod
    remove_new_container paykey_redis_prod
    if [[ -n "$old_redis" ]]; then docker rename "$old_redis" paykey_redis_prod; fi
    if [[ "$redis_was_running" == true ]]; then docker start paykey_redis_prod >/dev/null; fi
    if [[ -n "$old_backend" ]]; then docker rename "$old_backend" paykey_backend_prod; fi
    if [[ "$backend_was_running" == true ]]; then docker start paykey_backend_prod >/dev/null; fi
    if [[ "$environment_promoted" == true ]]; then
      if [[ -f "$release_dir/previous.env" ]]; then
        cp "$release_dir/previous.env" /opt/paykey/.env
        chmod 600 /opt/paykey/.env
      else
        rm -f -- /opt/paykey/.env
      fi
    fi
  fi
  exit "${status:-1}"
}
trap rollback ERR INT TERM

rollback_needed=true
if [[ "$backend_was_running" == true ]]; then
  # Stop writers before copying. Failure here leaves the old container intact
  # and triggers restart; never recreate a container after a failed copy.
  docker stop --time 30 paykey_backend_prod >/dev/null
  if [[ "$has_uploads" == true ]]; then
    mkdir "$release_dir/uploads-backup"
    docker cp paykey_backend_prod:/app/uploads/. "$release_dir/uploads-backup/"
    cp -a "$release_dir/uploads-backup/." /opt/paykey/legacy-uploads/
  fi
  if [[ "$has_exports" == true ]]; then
    mkdir "$release_dir/exports-backup"
    docker cp paykey_backend_prod:/app/exports/. "$release_dir/exports-backup/"
    mkdir -p /opt/paykey/legacy-uploads/exports
    cp -a "$release_dir/exports-backup/." /opt/paykey/legacy-uploads/exports/
  fi
fi

# Legacy copies stay read-only inside the container. Give the application owner
# read/traverse access without broadening access for other host users.
chown -hR 1000:1000 /opt/paykey/legacy-uploads
find /opt/paykey/legacy-uploads -xdev -type d -exec chmod u+rx {} +
find /opt/paykey/legacy-uploads -xdev -type f -exec chmod u+r {} +
"${backend[@]}" run --rm --no-deps -T backend node <<'NODE'
const fs = require('node:fs');
const path = require('node:path');
if (process.getuid() !== 1000) throw new Error('Backend must run as the application user');
const root = process.env.STORAGE_ROOT;
const probe = fs.mkdtempSync(path.join(root, '.release-write-probe-'));
try {
  const file = path.join(probe, 'probe');
  fs.writeFileSync(file, 'storage-ready', { mode: 0o600 });
  if (fs.readFileSync(file, 'utf8') !== 'storage-ready') throw new Error('Storage read-back failed');
  fs.unlinkSync(file);
} finally {
  fs.rmdirSync(probe);
}
function checkLegacy(directory) {
  fs.accessSync(directory, fs.constants.R_OK | fs.constants.X_OK);
  for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
    const filename = path.join(directory, entry.name);
    if (entry.isDirectory()) checkLegacy(filename);
    else if (entry.isFile()) fs.accessSync(filename, fs.constants.R_OK);
  }
}
checkLegacy(process.env.LEGACY_UPLOADS_DIR);
console.log('Non-root storage writes and retained legacy-file reads are available');
NODE

if [[ "$backend_was_running" == true ]]; then
  old_backend="paykey_backend_rollback_${release_id}"
  docker rename paykey_backend_prod "$old_backend"
fi
if [[ "$redis_was_running" == true ]]; then
  docker stop --time 30 paykey_redis_prod >/dev/null
  old_redis="paykey_redis_rollback_${release_id}"
  docker rename paykey_redis_prod "$old_redis"
fi

"${infra[@]}" up -d --wait --wait-timeout 90 redis
# Schema changes are deliberately outside this application release. The
# read-only preflight already required the complete migration ledger to match.
"${backend[@]}" up -d --wait --wait-timeout 120 backend
docker exec paykey_backend_prod node scripts/audit-production.cjs --require-migrations-current

# Only promote validated environment configuration after dependency readiness.
printf 'backend=%s\nredis=%s\n' "$old_backend" "$old_redis" > "$release_dir/rollback-containers.txt"
cp "$candidate" "/opt/paykey/.env.next-${release_id}"
chmod 600 "/opt/paykey/.env.next-${release_id}"
mv "/opt/paykey/.env.next-${release_id}" /opt/paykey/.env
environment_promoted=true
ln -sfn "$release_dir" /opt/paykey/current-release
rollback_needed=false
trap - ERR INT TERM
echo "Release ${release_id} is ready. Previous containers, images, environment and upload snapshot were retained."
