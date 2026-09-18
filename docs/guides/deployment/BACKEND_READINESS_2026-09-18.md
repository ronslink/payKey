# Backend readiness — 18 September 2026

This record supersedes the original access and database uncertainty in
[the initial assessment](PRODUCTION_READINESS_2026-09-18.md). Work is prepared on
`codex/production-launch-gates` in [PR #4](https://github.com/ronslink/payKey/pull/4).
The current production services have not been replaced. A passing local test is
not evidence of a live provider transaction or production deployment.

## Current production evidence

- Read-only SSH inspection confirms healthy backend, website, admin and Redis
  containers on droplet `46.101.95.200`; approximately 29 GiB is free.
- A standalone client inside the running backend connects to DigitalOcean
  PostgreSQL at `paykey-db-do-user-18876815-0.d.db.ondigitalocean.com:25060/defaultdb`
  with certificate verification, TLS 1.3 and a read-only database session.
- Nginx terminates API TLS and proxies to `localhost:3000`, compatible with the
  new loopback-only binding. The old container currently publishes port 3000 on
  all interfaces and UFW is inactive; DigitalOcean network controls remain to be
  checked. The prepared release removes this direct backend exposure.
- The 35 applied migration names match the compiled migrations. This release
  needs no SQL migration and refuses pending migrations before stopping services.
- Runtime live Stripe/IntaSend configuration is present; simulation and signature
  bypass are disabled. Secret presence does not establish signed webhook delivery.
- The database CA is present. GitHub `PROD` has the approved Redis secret and
  payment/deployment configuration. Backup freshness/retention and database
  trusted-source controls await renewed 1Password CLI access for `doctl`.
- Email and SMS still use `MOCK`. Production has no Firebase service-account file.
  The ignored local credential matches mobile project `paydome-9f9a7`; a scoped
  Google credential exchange succeeded without sending a notification. Automatic
  approval review blocked transferring it to production pending explicit approval
  for that credential and destination. No credential was transferred.

## Changes and necessary verification

| Change | Functional evidence and limit |
| --- | --- |
| New Stripe wallet charges require `STRIPE_WALLET_FUNDING_ENABLED=true` | Six focused Stripe tests passed with real Nest/JWT/PostgreSQL/Redis and simulated provider HTTP. Disabled/unset rejects both KES and EUR before provider calls or pending records; subscriptions and existing settlement continue. |
| M-Pesa subscriptions use server-defined KES prices and customer-approved renewals | Seven focused API/database tests passed for ownership, verification, duplicate callbacks, exact periods, uncertain initiation and paid-access preservation. Includes reproduced fixes for historical renewal jobs downgrading Stripe access and preference updates overwriting a paid extension. Actual handset/provider acceptance remains required. |
| Non-root backend and persistent private storage | Linux image built with lifecycle scripts disabled and started as UID 1000 against isolated PostgreSQL 17/Redis. Native bcrypt and application private-file write/read/delete passed. Legacy reading passed and writes to its read-only mount failed as expected. Disposable services were removed. |
| Dependency and workflow hardening | Verified commit pins replace mutable action references. Linux backend and clean-context website builds pass with `npm ci --ignore-scripts`. Optional baseline generation uses fixed installed Git paths; baseline was not changed. The environment writer has a fixed exclusive-create destination. |
| Deployment configuration and rollback | Nine configuration/audit checks pass, including Compose parsing and default-off card funding. Shell syntax passes. Live replacement and rollback have not been executed. |
| Website release hold | Backend CI only calls website release when repository variable `WEBSITE_RELEASE_ENABLED` is exactly `true`; it is currently unset. Billing UI remains held until provider acceptance. A separate CI job still tests billing/deletion and builds the website on pull requests. |

Provider HTTP is simulated and external calls blocked in payment regression
tests; they validate application behavior, not the provider account. Tests are
limited to payment integrity, authorization, paid access, startup and data
preservation needed for operation.

A final cross-provider review found that customers could initiate competing
subscription payments. The prepared guard rejects a second payable attempt
under the account billing lock. Stripe customer identity persists independently
of checkout rollback and is reused across email changes, allowing recovery after
an accepted checkout response is lost. Bank initiation also preserves existing
paid access. Bank and wallet alternatives reject competing payable attempts
before any provider initiation or balance deduction. Independent review confirmed
the gaps are closed. The final three integration suites passed all eight tests,
including lost-response recovery, email change and normal paid activation;
23 Stripe lifecycle unit tests also passed. Production type checking and lint
regression passed with zero new diagnostics. Evidence is retained in
`backend/test-results/backend-readiness-competing-providers.log` and
`backend-readiness-stripe-billing-unit.log`. Fresh CI remains required.

## Release decision

The latest passing backend CI at `2fdc9d3` predates this work. SonarCloud on that
head failed both security and reliability ratings: lifecycle scripts, mutable
actions, root runtime, PATH-based Git, the environment destination and a floating
point assertion. Fixes are prepared; fresh CI, CodeQL and Sonar analysis are
required. No alerts were dismissed and no gate was disabled.

Before deploying the backend: push and pass fresh checks, verify managed database
protection, and keep both release switches
above disabled. The release script preserves existing files, containers, images,
Redis storage and environment; it promotes configuration only after readiness.
Review the [release runbook](../../../deploy/PRODUCTION_RELEASE.md) before running it.

Before opening paid customer access: verify real provider callback configuration
and signed delivery, Stripe sandbox purchase/activation/cancellation and an
explicitly authorized M-Pesa funding/subscription/payout acceptance flow. No real
charge or payout is authorized by a readiness test. Enable Stripe wallet funding
only after an actual Stripe-to-IntaSend liquidity arrangement is verified; none
currently exists in the application.

Configure and verify offered notification channels, then test the actual signed
Android 23 against the released backend, including reviewer login, private
documents and system pickers. Play releases are prepared but unpublished; see
[the Play Console record](PLAY_CONSOLE_PREPARATION_2026-09-18.md). A new GitHub
Release/tag is unnecessary: deployment identifies the tested Git commit and image
digest. A changed future Android binary requires a new version code.
