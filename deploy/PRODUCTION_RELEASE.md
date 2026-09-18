# Production release operations

`backend-ci.yml` is the single backend release path. Main-branch pushes and the
three manual entrypoints all require lint, build, unit/security tests, deployment
configuration tests, schema setup and E2E tests to succeed. A failed check blocks
image publication and deployment. The website is released from the same commit
only after the backend succeeds; admin releases remain independent.
Backend and website build configuration use Node 24 LTS; the website workflow
also runs its customer billing/session regression tests before publishing an image.

Lint uses `backend/eslint-baseline.json`, generated from tracked source at the
recorded pre-hardening commit, via `node scripts/lint-regression.cjs
--generate-from-head`. Normal CI never regenerates it. Each allowance records
file, rule, severity, normalized source-snippet hash and count, not line numbers.
New files have no allowance; any added diagnostic or increased count fails CI.
Legacy lint debt remains visible in the complete `lint-report.json` test-result
artifact. Build/type checking and every E2E assertion still fail normally. Do
not regenerate the baseline to make a failed release pass; fix the new issue.

## Before the first hardened release

The manual `backend-deploy.yml` entrypoint defaults to `inspect`: it uses the
existing GitHub `PROD` SSH credential to read the running container's database
identity, verified TLS session, schema metadata and migration ledger. It does not
restart services or run migrations. The `release` option is restricted to `main`
and invokes the required CI and release chain. A separate GitHub Release/tag is
not required: deployed images and the website are tied to the tested commit.

1. Recover trusted SSH access and confirm the current DigitalOcean droplet and
   database cluster. Run only read-only checks until the target is confirmed.
2. In the GitHub `PROD` environment, supply `REDIS_PASSWORD` (new random value,
   at least 16 characters), `JWT_SECRET` (at least 32 characters), `DATABASE_URL`,
   live IntaSend keys and either `INTASEND_CHALLENGE` or `INTASEND_WEBHOOK_SECRET`.
   Supply a live Stripe API key and its `whsec_` webhook secret. Preserve the existing signing
   secret unless deliberately invalidating existing sessions.
3. Install the database CA at `/opt/paykey/ca-certificate.crt`. Optional Firebase
   credentials belong at `/opt/paykey/secrets/firebase-service-account.json`,
   outside Git/image layers. Email/SMS credentials and provider variables must
   be supplied separately if those channels are offered.
4. Verify database backup retention and restore a recent backup into an isolated
   database. This launch adds no migrations, and its read-only preflight rejects
   any pending migration before stopping the existing application. If legacy SQL
   is pending, inspect its schema/data effects, rehearse it and recovery against
   the restored database, and apply the reviewed SQL in a separate migration
   operation before retrying the application release. Do not mark unexecuted SQL
   as applied merely to bypass this check. Record the backup/restore identifier,
   time and release commit. The release script does not create a managed-database
   backup or claim one has been tested.
5. Verify ingress terminates TLS and proxies to host loopback port 3000. Backend
   public port exposure is removed. Confirm firewall/trusted-source settings.

## What the release script does

The runner writes a new mode-0600 `.env.candidate` with validated keys and
escaped Compose quoting, preserving dollars, quotes and multiline keys. It never sources the file as shell code. The
release is staged under `/opt/paykey/releases/<commit>-<run>-<attempt>`.

The remote script validates Compose, pulls the registry **digest** built from
the tested commit, and runs the standalone audit with a read-only DB session.
The audit compares every compiled migration's TypeORM name with the applied
ledger and requires no pending SQL before replacement. These steps do not
bootstrap Nest, run seeders, or apply migrations.

For replacement it stops the old backend, copies `/app/uploads` into a retained
release snapshot and `/opt/paykey/legacy-uploads`, copies `/app/exports` into a
separate snapshot and `/opt/paykey/legacy-uploads/exports`, and keeps the old container.
Failure to copy aborts replacement. New private/public storage is persisted at
`/opt/paykey/storage`; the legacy directory is mounted read-only. The old Redis
named volume is discovered and reused, including when the Redis password is
changed. No volume, old container or rollback image is pruned.

The script then starts Redis and the new backend, requires PostgreSQL/Redis
readiness at `/health/ready`, and verifies the migration ledger again through the
read-only audit. It never runs migration SQL. Only after success does it promote
`.env.candidate` to `/opt/paykey/.env` and update `current-release`. Keep any
separate migration operation's output private because SQL output may contain
sensitive values. Never print `.env`, `docker inspect` environment contents, or
unrestricted `docker compose config` in CI logs.

## Rollback and verification

On a replacement failure the script removes only containers bearing the current
release's Compose project label and restarts retained backend/Redis containers.
It **does not reverse database migrations**. Backward-compatible migrations and
a separately tested database recovery plan are prerequisites.

Previous image IDs, container names, `.env` and upload snapshots are retained in
the release directory. Keep enough disk capacity for them; perform separately
reviewed retention cleanup only after acceptance. Restoring an old vulnerable
backend may require keeping the affected routes blocked at ingress.

For a running hardened release, use:

```sh
docker exec paykey_backend_prod node scripts/audit-production.cjs --require-migrations-current
```

The output includes only DB hostname/database, server identity, session TLS,
applied/pending migration names, release commit and configuration presence. It
uses `default_transaction_read_only=on` and `BEGIN READ ONLY`; it imports only
the compiled connection helper and `pg`, not the application.

After release, verify the public site/API, restricted route removal, tenant
isolation, private download ownership, notification delivery, and the actual
signed mobile binaries. Controlled provider funding/payout acceptance and store
publication still require their own checks. Local tests are not proof that the
live provider accounts, backup policy or running database target are correct.
