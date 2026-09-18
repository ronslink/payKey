# Production release operations

`backend-ci.yml` is the single backend release path. Main-branch pushes and the
three manual entrypoints all require lint, build, unit/security tests, deployment
configuration tests, schema setup and E2E tests to succeed. A failed check blocks
image publication and deployment. Website release additionally requires the
repository variable `WEBSITE_RELEASE_ENABLED=true`; leave it unset until billing
provider acceptance is complete. When enabled, the website follows the successful
backend release from the same commit. Admin releases remain independent.
Backend and website build configuration use Node 24 LTS; the website workflow
also runs its customer billing/session regression tests before publishing an image.
Website billing/deletion tests and its production build run on pull requests
even while website publication is held.

Lint uses `backend/eslint-baseline.json`, generated from tracked source at the
recorded pre-hardening commit, via `node scripts/lint-regression.cjs
--generate-from-head`. Normal CI never regenerates it. Each allowance records
file, rule, severity, normalized source-snippet hash and count, not line numbers.
New files have no allowance; any added diagnostic or increased count fails CI.
Legacy lint debt remains visible in the complete `lint-report.json` test-result
artifact. Build/type checking and every E2E assertion still fail normally. Do
not regenerate the baseline to make a failed release pass; fix the new issue.

## Payment architecture for this release

Prepared routing keeps M-Pesa in KES as the default. Stripe card wallet payments
support explicit KES or EUR, but new charges are disabled unless the GitHub
`PROD` variable `STRIPE_WALLET_FUNDING_ENABLED` is exactly `true`. Leave it unset
until the funding arrangement below is verified. This guard does not disable
Stripe subscriptions or settlement of existing payments. This code is not
deployed; fresh CI and real-provider acceptance remain outstanding. IntaSend's
current [homepage FAQ](https://intasend.com/) says it is
not supporting cards, despite its older [card guide](https://developers.intasend.com/docs/accept-card-payment)
and [fund-wallet guide](https://developers.intasend.com/docs/fund-wallet). Do not
depend on the legacy IntaSend hosted-card route.

M-Pesa funding targets the employer's IntaSend wallet through `wallet_id`
([fund wallet](https://developers.intasend.com/docs/fund-wallet)); payroll uses
that wallet for [external transfers](https://developers.intasend.com/docs/external-transfers)
and requires [funded available balance](https://developers.intasend.com/docs/send-money).
[Internal transfers](https://developers.intasend.com/docs/internal-transfers)
operate only between owned IntaSend wallets. No Stripe-to-IntaSend funding bridge
exists in this application. This affects every Stripe wallet charge, including
KES without FX, and is separate from Stripe subscription billing.

## Before the first hardened release

The manual `backend-deploy.yml` entrypoint defaults to `inspect`: it uses the
existing GitHub `PROD` SSH credential to read the running container's database
identity, verified TLS session, schema metadata and migration ledger. It does not
restart services or run migrations. The `release` option is restricted to `main`
and invokes the required CI and release chain. A separate GitHub Release/tag is
not required: deployed images and the website are tied to the tested commit.

1. Reconfirm the target through read-only inspection. Existing deployment-key
   access is restored locally and in GitHub. The running backend is verified on
   DigitalOcean managed PostgreSQL over certificate-verified TLS 1.3; all 35
   migration names match, with no pending SQL. The database CA is mounted read-only.
2. In the GitHub `PROD` environment, supply `REDIS_PASSWORD` (new random value,
   at least 16 characters), `JWT_SECRET` (at least 32 characters), `DATABASE_URL`,
   live IntaSend keys and either `INTASEND_CHALLENGE` or `INTASEND_WEBHOOK_SECRET`.
   Supply a live Stripe API key and its `whsec_` webhook secret. The existing live
   `STRIPE_PUBLISHABLE_KEY` is configured and verified as a GitHub `PROD` variable;
   the workflow, environment writer and Compose require and pass it at runtime.
   The approved `REDIS_PASSWORD` is already stored in `PROD`. Preserve the existing signing
   secret unless deliberately invalidating existing sessions.
3. Install the database CA at `/opt/paykey/ca-certificate.crt`. Optional Firebase
   credentials belong at `/opt/paykey/secrets/firebase-service-account.json`,
   outside Git/image layers. Production currently has no Firebase credential;
   staging the verified local credential awaits the user's explicit approval.
   Email/SMS credentials and provider variables must
   be supplied separately if those channels are offered.
4. Verify database backup freshness/retention and trusted sources; these remain
   unverified after another 1Password CLI authorization timeout. This launch adds no migrations,
   and its read-only preflight rejects
   any pending migration before stopping the existing application. If legacy SQL
   is pending, inspect its schema/data effects, restore a recent backup into an
   isolated database, rehearse the SQL and recovery there, and apply the reviewed SQL in a separate migration
   operation before retrying the application release. Do not mark unexecuted SQL
   as applied merely to bypass this check. Record the backup/restore identifier,
   time and release commit when SQL is required. No restore rehearsal is required
   for the current application-only rollout with all migrations already applied.
   The release script does not create a managed-database
   backup or claim one has been tested.
5. Verify ingress terminates TLS and proxies to host loopback port 3000. Backend
   public port exposure is removed. Confirm firewall/trusted-source settings.
6. Resolve provider liquidity before releasing any Stripe wallet payments (KES
   or EUR). Stripe settlement
   currently credits only the application's KES ledger; payroll draws from each
   employer's IntaSend working wallet. No bridge funds that wallet, and no
   pre-funded balance or other operational mechanism has been verified. Agree and
   verify the actual funding arrangement before enabling card wallet charges.
   Keep `STRIPE_WALLET_FUNDING_ENABLED` absent or `false` in the meantime; this
   permits the security release without exposing unfunded new card top-ups.
   Hourly balance observation
   now logs discrepancies without overwriting
   the ledger; this protects recorded credit but does not fund payouts.
7. The enabled Paydome subscription webhook lacks `payment_intent.succeeded`.
   Add it only after the corrected backend is deployed and the funding path is
   agreed. First verify Stripe sandbox checkout, signed delivery and settlement;
   monitor the first genuine authorized live purchase. Do not run synthetic
   live-card tests ([Stripe testing guidance](https://docs.stripe.com/testing)).

See [the backend readiness record](../docs/guides/deployment/BACKEND_READINESS_2026-09-18.md)
for the current verification and remaining prerequisites. Functional CI at
`2fdc9d3` predates the M-Pesa subscription and final hardening work; fresh CI is
required. Android 23 has been uploaded and prepared in Play Console, but no
production deployment, provider transaction or mobile publication has occurred.

## What the release script does

The runner writes a new mode-0600 `.env.candidate` with validated keys and
escaped Compose quoting, preserving dollars, quotes and multiline keys. It never sources the file as shell code. The
release is staged under `/opt/paykey/releases/<commit>-<run>-<attempt>`.

Dependency installation disables lifecycle scripts; both locked applications
were built successfully in Linux with that setting. The backend image runs as
UID/GID 1000 (`node`). The release prepares only dedicated application storage
for that user and verifies private writes and retained-file reads before starting
the replacement. Optional Firebase files remain outside the image, readable
through the application group with a mode-0750 directory and mode-0640 file.

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
It **does not reverse database migrations**. If a separate SQL operation is
introduced, review backward compatibility and rehearse recovery before that
operation; the current application release requires no SQL.

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
