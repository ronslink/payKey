#!/usr/bin/env bash
# Release the tested website only after its matching backend is ready.
set -Eeuo pipefail
umask 077

release_dir=$(realpath -e "${1:?Pass the staged website release directory}")
[[ "$release_dir" =~ ^/opt/paykey/releases/[a-f0-9]{40}-[0-9]+-[0-9]+/website$ ]] || { echo 'Invalid staged website release directory'; exit 1; }
release_id=$(basename "$(dirname "$release_dir")")
[[ "${RELEASE_COMMIT:-}" =~ ^[a-f0-9]{40}$ && "$release_id" == "$RELEASE_COMMIT-"* ]] || { echo 'Release commit does not match the staged release'; exit 1; }
[[ "${WEBSITE_IMAGE:-}" =~ ^[a-z0-9][a-z0-9._/-]*@sha256:[a-f0-9]{64}$ ]] || { echo 'An immutable website image digest is required'; exit 1; }
export WEBSITE_IMAGE RELEASE_COMMIT
project="paykey-website-$release_id"
website=(docker compose -p "$project" --env-file /dev/null -f "$release_dir/deploy/docker-compose.website.yml")

docker info >/dev/null
docker network inspect paykey-network-prod >/dev/null
[[ $(docker inspect --format '{{.State.Running}}' paykey_backend_prod) == true ]] || { echo 'Backend must be running before the website release'; exit 1; }
[[ $(docker inspect --format '{{index .Config.Labels "org.opencontainers.image.revision"}}' paykey_backend_prod) == "$RELEASE_COMMIT" ]] || { echo 'Backend release does not match this website commit'; exit 1; }

# These are read-only requests: no account, checkout, or payment is created.
# Public HTTPS also checks that the reverse proxy reaches the ready backend.
docker exec -i paykey_backend_prod node <<'NODE'
async function read(path) {
  const response = await fetch(`https://api.paydome.co${path}`, {
    signal: AbortSignal.timeout(8000), headers: { 'Cache-Control': 'no-cache' },
  });
  if (!response.ok) throw new Error(`Backend check failed: ${path} (${response.status})`);
  return response.json();
}
(async () => {
  const health = await read('/health/ready');
  if (health.status !== 'ready' || health.checks?.database !== 'up' || health.checks?.redis !== 'up') {
    throw new Error('Backend dependencies are not ready');
  }
  const schema = await read('/api-json');
  for (const [path, method] of [
    ['/subscriptions/plans', 'get'], ['/subscriptions/current', 'get'],
    ['/subscriptions/subscribe', 'post'], ['/subscriptions/auto-renew', 'post'],
    ['/payments/subscriptions/checkout-status/{sessionId}', 'get'],
  ]) {
    if (!schema.paths?.[path]?.[method]) throw new Error(`Required billing route is missing: ${path}`);
  }
  if (schema.paths?.['/testing/reset-payroll']) throw new Error('Test-only payroll reset route is still exposed');
  console.log('Matching backend is ready and exposes the required billing routes');
})().catch((error) => { console.error(error.message); process.exit(1); });
NODE

"${website[@]}" config --quiet
"${website[@]}" pull website
"${website[@]}" run --rm --no-deps --entrypoint nginx website -t

old_website=""
website_was_running=false
rollback_needed=false
if docker container inspect paydome_website_prod >/dev/null 2>&1; then
  [[ $(docker inspect --format '{{.State.Running}}' paydome_website_prod) == true ]] || { echo 'Existing website is stopped; recover or inspect it before releasing'; exit 1; }
  website_was_running=true
  docker inspect --format '{{.Image}}' paydome_website_prod > "$release_dir/previous-website-image.txt"
fi
rollback() {
  local status=$?
  if [[ "$status" -eq 0 ]]; then status=1; fi
  trap - ERR INT TERM
  set +e
  if [[ "$rollback_needed" == true ]]; then
    echo 'Website release failed. Restoring the retained website container.'
    if [[ $(docker inspect --format '{{index .Config.Labels "com.docker.compose.project"}}' paydome_website_prod 2>/dev/null || true) == "$project" ]]; then
      docker rm -f paydome_website_prod >/dev/null
    fi
    if [[ -n "$old_website" ]]; then docker rename "$old_website" paydome_website_prod; fi
    if [[ "$website_was_running" == true ]]; then docker start paydome_website_prod >/dev/null; fi
  fi
  exit "$status"
}
trap rollback ERR INT TERM
rollback_needed=true
if [[ "$website_was_running" == true ]]; then
  docker stop paydome_website_prod >/dev/null
  docker rename paydome_website_prod "paydome_website_rollback_$release_id"
  old_website="paydome_website_rollback_$release_id"
fi
"${website[@]}" up -d --no-deps website

ready=false
for attempt in {1..20}; do
  if docker exec paydome_website_prod sh -c 'test -s /usr/share/nginx/html/index.html && wget -q -O /dev/null http://127.0.0.1/account'; then
    ready=true
    break
  fi
  sleep 3
done
[[ "$ready" == true ]] || { echo 'New website did not become ready'; false; }
curl --fail --silent --show-error --max-time 15 --output /dev/null https://paydome.co/account
printf '%s\n' "$WEBSITE_IMAGE" > "$release_dir/website-image.txt"
trap - ERR INT TERM
echo "Website release $RELEASE_COMMIT is ready. Previous container and image are retained for rollback."
