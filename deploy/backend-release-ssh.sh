#!/usr/bin/env bash
# Native runner SSH can read runner-owned 0700/0600 staging files. Keep secrets
# private instead of making them readable by a container action's different UID.
set -Eeuo pipefail
set +x
umask 077

mode=${1:?Pass upload or deploy}
[[ "$mode" == upload || "$mode" == deploy ]] || { echo 'Invalid release transport mode'; exit 1; }
[[ "${DO_HOST:-}" == 46.101.95.200 && "${DO_USERNAME:-}" == root ]] || { echo 'Unexpected production SSH target'; exit 1; }
[[ "${RELEASE_ID:-}" =~ ^[a-f0-9]{40}-[0-9]+-[0-9]+$ ]] || { echo 'Invalid release identifier'; exit 1; }
[[ -n "${DO_SSH_KEY:-}" ]] || { echo 'A deployment SSH key is required'; exit 1; }

known_hosts="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/production-known-hosts"
[[ -s "$known_hosts" ]] || { echo 'Verified production host key is required'; exit 1; }
ssh_directory=$(mktemp -d "${RUNNER_TEMP:?}/paykey-release-ssh.XXXXXX")
key_file="$ssh_directory/key"
cleanup() {
  rm -f -- "$key_file"
  rmdir -- "$ssh_directory"
}
trap cleanup EXIT
printf '%s\n' "$DO_SSH_KEY" > "$key_file"
chmod 600 "$key_file"
unset DO_SSH_KEY
ssh_options=(
  -i "$key_file"
  -o BatchMode=yes
  -o IdentitiesOnly=yes
  -o StrictHostKeyChecking=yes
  -o UpdateHostKeys=no
  -o "UserKnownHostsFile=$known_hosts"
  -o GlobalKnownHostsFile=/dev/null
  -o HostKeyAlgorithms=ssh-ed25519
  -o ConnectTimeout=30
)
target="$DO_USERNAME@$DO_HOST"
destination="/opt/paykey/releases/$RELEASE_ID"

if [[ "$mode" == upload ]]; then
  source_directory="${GITHUB_WORKSPACE:?}/release"
  for filename in .env.candidate deploy/deploy-backend.sh deploy/docker-compose.backend.yml deploy/docker-compose.infra.yml; do
    [[ -s "$source_directory/$filename" && -f "$source_directory/$filename" && ! -L "$source_directory/$filename" ]] || { echo 'A regular staged release file is missing'; exit 1; }
  done
  [[ $(stat -c %a "$source_directory/.env.candidate") == 600 ]] || { echo 'Candidate configuration must remain private'; exit 1; }
  ssh -n "${ssh_options[@]}" "$target" "set -eu; umask 077; test ! -L /opt/paykey/releases; test ! -L '$destination'; test ! -L '$destination/deploy'; install -d -m 700 '$destination/deploy'; test ! -e '$destination/.env.candidate'; test ! -L '$destination/.env.candidate'"
  scp -p "${ssh_options[@]}" "$source_directory/.env.candidate" "$target:$destination/.env.candidate"
  scp -p "${ssh_options[@]}" \
    "$source_directory/deploy/deploy-backend.sh" \
    "$source_directory/deploy/docker-compose.backend.yml" \
    "$source_directory/deploy/docker-compose.infra.yml" \
    "$target:$destination/deploy/"
  ssh -n "${ssh_options[@]}" "$target" "set -eu; test -s '$destination/.env.candidate'; test -f '$destination/.env.candidate'; test ! -L '$destination/.env.candidate'; test \"\$(stat -c %a '$destination/.env.candidate')\" = 600"
  echo 'Release uploaded with private configuration permissions; live services unchanged.'
else
  [[ -n "${DOCKER_USERNAME:-}" && -n "${DOCKER_PASSWORD:-}" ]] || { echo 'Registry credentials are required'; exit 1; }
  # Feed quoted assignments over the encrypted stdin stream, never command-line
  # arguments or logs. The remote shell is explicitly Bash for printf %q syntax.
  {
    printf 'set -eu\n'
    printf 'DOCKER_USERNAME=%q\n' "$DOCKER_USERNAME"
    printf 'DOCKER_PASSWORD=%q\n' "$DOCKER_PASSWORD"
    printf 'RELEASE_ID=%q\n' "$RELEASE_ID"
    cat <<'REMOTE'
printf '%s' "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
unset DOCKER_PASSWORD
bash "/opt/paykey/releases/$RELEASE_ID/deploy/deploy-backend.sh" "/opt/paykey/releases/$RELEASE_ID"
REMOTE
  } | ssh "${ssh_options[@]}" "$target" bash -s
fi
