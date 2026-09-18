# Production and launch readiness assessment

Checked: 18 September 2026, approximately 07:22 UTC.

Local remediation was subsequently implemented. See
[the launch gate implementation report](LAUNCH_GATE_FIXES_2026-09-18.md) for fixes,
verification and remaining production prerequisites. This assessment below
describes the originally observed deployment; local fixes are not evidence of a
production rollout.

## Decision

**The public website, admin frontend and backend API are online. The backend is serving database-backed requests. Do not treat this as readiness for a broad customer launch: critical security and onboarding gaps remain.**

DigitalOcean managed PostgreSQL is the documented and configured production target. Its use by the currently running backend could **not** be independently confirmed: the documented server rejects the three existing local SSH identities, and the protected infrastructure endpoint correctly requires authentication. No production changes, account creation, payments, migrations or destructive endpoint calls were performed.

## Verified production evidence

| Check | Result | Meaning / limit |
| --- | --- | --- |
| `https://paydome.co/` and `https://www.paydome.co/` | HTTP 200; Paydome website | Public marketing site is reachable through Cloudflare. |
| `https://admin.paydome.co/` | HTTP 200; PayKey Admin | Admin frontend is reachable; authenticated admin flows were not exercised. |
| `https://api.paydome.co/` and `/api` | HTTP 200; Swagger UI at `/api` | Backend HTTP service is running. Swagger alone is not a database readiness check. |
| `https://api.paydome.co/countries` | HTTP 200 with stored country records | Consistent with a functioning application database: `CountriesService.findAll()` reads the TypeORM repository. It does not identify the database host. |
| `/workers` and `/api/admin/analytics/infra` | HTTP 401 without credentials | These routes enforce authentication. |
| `https://api.paydome.co/api-json` | HTTP 200; 266 documented paths | Live schema still advertises `POST /testing/reset-payroll` without operation security metadata. Destructive behavior was not invoked. |
| Website's live JavaScript bundle | Trial button has no action; no Apple/Google store links found | The deployed site's customer acquisition flow is incomplete, consistent with local source. |
| Latest recorded backend CI/deploy | Successful on 21 July 2026 | Build, tests, migration and deployment completed. Logs reported backend healthy and two migrations applied. This is historical evidence, not today's container inspection. |

Deployment evidence: [GitHub Actions run 29826804125](https://github.com/ronslink/payKey/actions/runs/29826804125), commit `b839ec12e8903011b1a697838050aabd09b02adf`.

Local HEAD: `1193c25188f2fd16c5f29ced5b800bff4edcf68a` (27 July 2026; mobile version update). The working tree contains existing uncommitted changes, including database and webhook hardening. Those changes must not be assumed deployed. The current production image digest/commit remains unverified.

## DigitalOcean database status

Evidence for the intended setup:

- `deployment_log.md` documents server `46.101.95.200`, application directory `/opt/paykey`, and a DigitalOcean managed PostgreSQL 17 database named `paykey-db` in London.
- `deploy/docker-compose.backend.yml` sets `NODE_ENV=production`, injects `DATABASE_URL`, and mounts the database CA certificate.
- `deploy/docker-compose.infra.yml` runs Redis; it does not run a PostgreSQL container.
- `backend/src/config/database.config.ts:59` selects `DATABASE_URL` before local DB fields.
- Mobile release source defaults its API URL to `https://api.paydome.co`; installed binaries were not inspected.

The original deployment key, July 24 deployment key and default SSH identity all returned `Permission denied` against `root@46.101.95.200`. Local `.env` files are development/example configuration and cannot establish the live database target. A clarification about the current production host/access method is pending.

Required direct verification once access is available:

1. Confirm current container status, restart counts, image digest and release commit; inspect only sanitized runtime configuration.
2. Parse the running backend's `DATABASE_URL` and record only hostname, port and database name. Confirm its DigitalOcean cluster identity against the control panel; do not print credentials.
3. From the backend container, use a standalone PostgreSQL client in a read-only session to query database identity, `SELECT 1`, and `pg_stat_ssl` for that connection. Do not bootstrap the application, because startup can run migrations and seed data.
4. Compare the applied migration ledger with the deployed image's migration files. Do not run migrations as part of verification.
5. Confirm database trusted sources/firewall, capacity, backup retention and a successful restore into a separate database. These were not verified in this assessment.

## Launch gates, in priority order

### 1. Contain and fix critical security issues

| Finding and evidence | Required outcome |
| --- | --- |
| Testing module loads unconditionally (`backend/src/app.module.ts:110`); public reset controller has no authentication (`backend/src/modules/testing/testing.controller.ts:8`) and its service deletes payroll/tax records. Live schema advertises the route. | Remove testing routes from production. Verify the reset route is absent after release. An immediate authenticated operational change should block this route while the fix is prepared. |
| Registration validation does not whitelist input (`auth.controller.ts:20`); registration and user creation spread submitted properties (`auth.service.ts:90`, `users.service.ts:30`). A local, mocked reproduction confirmed an injected administrator role survived into the saved entity and issued JWT. | Explicitly allow registration fields; assign roles, balances and privileged account fields exclusively on the server. Add regression coverage before enabling public signup. |
| Committed webhook code permits simulation/signature bypass in production. Local uncommitted edits add production restrictions (`payments.controller.ts:395,430`). | Review and commit the hardening, verify the deployed image contains it, and test rejection of invalid/unsigned production callbacks and duplicate deliveries. |
| Government payroll spreadsheets and worker documents are written under `uploads/`, which `main.ts:22` serves publicly. Examples: `gov-integrations/services/shif.service.ts:17` and `uploads/uploads.service.ts:56`. | Move sensitive files outside the public static root and require ownership-checked downloads. Confirm already-created private files are no longer exposed by public URLs. |
| Missing Google audiences permit an unverified login fallback (`auth.service.ts:184`); missing JWT secret uses a hardcoded fallback (`jwt.strategy.ts:31`). Runtime values are unknown. | Fail production startup or disable the affected authentication method when configuration is missing. Confirm expected audiences and real signing secrets without displaying their values. |

Auth and testing findings are in committed source with no local modifications. No live privilege escalation or deletion was attempted. Review privileged accounts and payment integrity after containment; the audit does not establish that exploitation occurred.

### 2. Verify and harden production data operations

- Complete the direct database/backup checks above and rehearse restore and application rollback outside production.
- Enforce certificate verification: current DB code sets `rejectUnauthorized: false` despite the CA mount (`database.config.ts:64`).
- Fail closed when production DB configuration is missing: the alternate DB configuration enables schema synchronization with `isTest || true` (`database.config.ts:187`).
- Confirm persistent file storage. The checked production Compose file does not mount an uploads volume; files written inside a replaced container can be lost. Separate private storage from public avatars/assets.
- Remove the backend's direct Docker socket mount or replace it with narrowly scoped operational access. The current mount gives a compromised backend control over the host's Docker daemon.
- Verify credential rotation/revocation. `deploy_key` remains tracked at HEAD even though deleted locally, and Redis authentication is embedded in Compose. Removing a file locally or adding ignore rules does not revoke credentials or remove history.
- Add readiness checks that exercise PostgreSQL and Redis, plus external uptime/error/queue monitoring. Current deployment checks only request Swagger at `/api`.

### 3. Finish the customer onboarding path

- Connect the website's Get the app, trial and pricing actions to actual approved store listings, a controlled beta distribution link, or a working web signup flow.
- Source evidence: `website/src/sections/HomeHero.tsx:53`, `website/src/pages/Pricing.tsx:187`, `website/src/components/Navbar.tsx:106`. Live bundle inspection confirms the missing trial action and store links.
- Verify a real user's registration, login, account recovery/support path, worker creation, payroll calculation and payslip access using an approved test account/environment.

### 4. Decide and complete the paid subscription path

- Mobile Android/iOS release builds disable external subscription checkout by default (`mobile/lib/core/config/app_environment.dart:49`); the subscription page reports plan changes unavailable (`subscription_management_page.dart:545`). Website pricing buttons also have no checkout action.
- Choose a free initial release or complete a supported paid subscription purchase flow for the intended distribution channels. Verify store/account requirements before enabling checkout; simply changing the mobile flag is not a complete billing solution.
- Test purchase, entitlement activation, renewal, cancellation, failure and duplicate webhook handling end to end.

### 5. Validate real payment and communication services

- Confirm live IntaSend/Stripe credentials and provider account readiness, callback URLs, webhook verification and simulation disabled in production. Compose's `INTASEND_IS_LIVE=true` is intent, not proof that live payment processing is operational.
- After security fixes, conduct an explicitly approved low-value funding/payout test and reconcile provider status, internal balances, payroll records and webhook retries. No payment was initiated during this audit.
- Verify real email/SMS/push configuration and delivery. Backend defaults include mocked email/SMS and mocked push when Firebase credentials are absent (`notifications.service.ts:77,129,231`).
- Mobile push-token upload/refresh is unfinished (`mobile/lib/core/services/notification_service.dart:36`). Complete it if notifications are part of launch scope.

### 6. Verify mobile distribution

- Android CI builds an APK but does not restore ignored signing/Firebase files or publish a store release (`.github/workflows/mobile-android.yml:31`). Securely configure repeatable signing and verify a production release in Play Console using the existing signing identity.
- iOS GitHub CI uses `--no-codesign` (`mobile-ios.yml:40`). Xcode Cloud configuration exists, so this does not mean the app is unpublished. Verify the actual archive, TestFlight/App Store status and production configuration in the Apple account.
- Test the actual release binaries against the production API; source defaults do not prove the configuration of installed apps.
- Employee payslip download is still a coming-soon action (`employee_payslips_page.dart:428`); either complete it or remove the launch promise.

### 7. Release and accept a defined launch version

- Review existing local changes, merge only intended fixes, and use the test-gated backend CI workflow. Record an immutable image digest/commit and a tested rollback target.
- Run migration validation on a restored/staging copy before any production migration; verify backup and recovery first.
- Run a controlled pilot covering employer signup, worker onboarding, payroll, chosen payment method, reporting and support. Obtain a clear acceptance result before broad promotion.

## Checks completed

- Read-only production HTTP/DNS checks and public API schema/website asset inspection.
- GitHub deployment status and filtered deployment log review.
- Backend production TypeScript check passed: `node node_modules/typescript/bin/tsc -p tsconfig.build.json --noEmit --incremental false`.
- Backend Jest unit suite passed: **9 suites, 87 tests**. Four webhook tests are in an untracked local test file. Existing tests did not prevent the registration/testing-route issues.
- Website and admin TypeScript application checks passed: `tsc -p tsconfig.app.json --noEmit --incremental false`.
- Safe local registration reproduction used mocked persistence and no network/database access.

Not completed: current container inspection, managed DB identity/SSL/migration/backup verification, real login/customer journeys, live payment acceptance, store publication verification or actual signed mobile builds. Historical CI success and local unit checks do not substitute for these gates.
