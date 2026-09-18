# Launch gate implementation — 18 September 2026

These changes are local and have not been deployed. The original production
assessment remains a snapshot of the deployed application before these fixes.
Paid subscriptions are required for launch; the customer billing path is the
website account flow and Stripe hosted checkout.

## Implemented

| Gate | Change |
| --- | --- |
| Public destructive routes | Testing routes load only in the test environment. Public registration rejects privileged fields; users start with the server-assigned role, free tier and zero balances. |
| Authentication | Production JWT configuration fails closed. Social login requires verified provider tokens and configured audiences. |
| Payment integrity | Live IntaSend callbacks cannot bypass verification. Settlement handles repeated clearing/final callbacks without duplicate balance movements. Provider secrets are removed from stored and returned callback metadata. |
| Paid launch | Website signup/login, authenticated plan selection, server-priced USD checkout and renewal controls are implemented. A return page reports active service only after backend verification. Signed Stripe callbacks settle once per invoice, handle out-of-order events and protect cancellation/renewal periods. Existing Stripe contracts cannot be overwritten by another payment method. Production requires live Stripe credentials. |
| Private files | Worker documents, government payroll files and accounting exports use persistent private storage and authenticated ownership checks. Existing file references resolve through preserved legacy storage. Public static serving is limited to avatar images. |
| Database safety | Production requires an explicit database URL and verified TLS. Schema synchronization and automatic startup migrations are disabled in production. A standalone read-only audit identifies the actual database host, TLS session and migration state without starting the app. |
| Deployment | A shared CI path tests before publishing an immutable image. Release scripts preserve uploads/exports and previous containers, reuse Redis storage, run explicit migrations and require database/Redis readiness before promoting configuration. |
| Mobile/customer access | Website calls to action lead to account/access pages. Approved app links are configurable. Push tokens register on login/startup/refresh and deactivate on logout. Employee payslips and document downloads use authenticated routes. Signing/Firebase restoration is configured for release workflows. |
| Employee isolation | Payslip history includes finalized and paid records and excludes drafts. Employees cannot download another worker's payslip or cancel another worker's leave, including within the same employer. |
| Account deletion | Unauthenticated requests cannot delete passwordless social accounts by email. Authenticated deletion verifies ownership. Recurring billing must be ended before deletion; worker activity records no longer prevent the tested cleanup flow. |

## Verification

Functional acceptance is based on necessary customer journeys, not test counts
or formatting. Each launch check must demonstrate an observable outcome:

| Necessary journey | Required evidence |
| --- | --- |
| Employer starts using the app | Registration/login produces a usable authenticated account while rejecting injected privileged fields. |
| Customer purchases access | The actual API and database move from free to paid only after a verified provider confirmation; retries create one receipt and cancellation removes access. |
| Employer runs payroll | Workers, configured tax data, draft/finalized payroll records and wallet movements persist correctly in PostgreSQL; external payouts use a provider double locally. |
| Employee accesses records | A real employee login can list finalized/paid payslips and download PDF bytes; drafts and another employee's records remain inaccessible. |
| Records remain private and durable | Owner-authenticated file downloads work; other accounts and anonymous/static paths fail; file paths survive container replacement through persistent storage. |
| Failed infrastructure blocks release | PostgreSQL or Redis failure produces readiness failure; deployment does not promote an unhealthy candidate. |

The last mile still requires a controlled **real provider payment and a signed
device build**. Browser mocks and unit tests alone cannot establish those outcomes.

Acceptance evidence deliberately excludes older tests that return early when
fixtures are missing or accept either success or failure responses. The employer
payroll tests establish calculation and persisted drafts; the funded-wallet test
establishes queued payout settlement. Its concurrent clearing/completion retries
are checked against persisted balances and transaction counts. The employee PDF
test uses seeded payroll records, but real login, authorization and generated PDF
bytes. Cash finalization is exercised by the worker-termination queue journey;
the separate payroll service test explicitly skips provider payouts.

Verification uses isolated PostgreSQL 17 and Redis containers with disposable
storage. E2E tests block external HTTP provider traffic and refuse a non-test
database. Provider responses in billing/browser tests are simulated; no real
charge, payout, signup, production migration or store publication was performed.

The final test results are recorded in the completion note below. The backend
release pipeline blocks new ESLint diagnostics against a checked-in baseline
generated from the original committed source. It retains the complete legacy
lint report; it does not claim that the existing repository is lint-clean.
Website changed-file lint passes; its full lint still reports nine pre-existing
issues in UI/main files.

### Completion evidence

- Backend: 22 unit/security suites, 216 tests passed. The complete existing E2E
  run passed 30 suites and 206 tests against disposable PostgreSQL 17 and Redis.
- The added real-application paid-subscription journey passed separately:
  signup/login, server-priced checkout, verified paid activation, concurrent
  invoice/checkout retries preserving one receipt and billing dates, and
  cancellation returning the account to Free. Stripe HTTP alone is simulated;
  the SDK uses its supported Fetch transport in this fixture because its Node
  TLS transport and the HTTP interceptor did not interoperate on local Node 24.
- The strengthened funded-wallet journey passed separately: concurrent clearing
  callbacks, completed-deposit retries and completed-payout retries preserve
  exact database balances and one salary transaction. IntaSend is a provider
  double; its real account and callback delivery still require acceptance.
- Employee login, own finalized/paid PDF downloads, draft/other-worker denial,
  private files, readiness failures and account deletion protection passed.
- Website production build, five billing/session tests and mocked browser
  journeys passed. Five mobile token-sync tests and touched-file analysis passed.
- Backend production container built successfully with Node 24. Six deployment
  configuration/audit tests passed. Backend lint comparison reports zero added
  diagnostics; existing debt remains visible. The two final journey files also
  pass focused lint.

No production deployment or provider transaction was performed. No claim of
current statutory-rate compliance or live mobile-store approval is made by these
local workflow checks.

## Remaining production gates

Access follow-up on 18 September 2026: `C:\doctl\doctl.exe` is installed
(version 1.147.0) but is not on the current PATH. Its saved `default` context
returned HTTP 401. The user subsequently identified a personal token in
1Password. That token successfully authenticated read-only `doctl` queries when
injected into a subprocess; its value was not printed or saved in the repository
or doctl configuration.

Confirmed directly through the DigitalOcean API:

| Resource | Verified state |
| --- | --- |
| Droplet `paykey-prod` (`539164900`) | Active, London `lon1`, public `46.101.95.200`, private `10.106.0.2`. |
| Managed cluster `paykey-db` (`2372047b-149b-4507-a640-6b456fa9a1d6`) | Online, PostgreSQL 17, `lon1`, one node, `db-s-1vcpu-1gb`. |
| Public website and `/countries` API | Both returned HTTP 200 on the follow-up check. |
| Public `/health/ready` | HTTP 404; the newly implemented readiness endpoint is not available on the current deployment. |

Subsequent 1Password CLI approval requests timed out, so database backups,
trusted sources, direct SQL connectivity and running-container configuration
remain unverified. Infrastructure inventory alone does not establish which
database the running backend is connected to. The valid credential remains in
1Password; further queries require approving its local CLI access prompt.
No cloud resources, firewall rules, database records or deployment settings were
changed by these checks.

Credential-source follow-up on 18 September 2026: the connected Vercel account
(`ronslinks-projects`) contains nine projects; none links to `ronslink/payKey`,
and none of their returned domains is a Paydome domain. Both the committed and
working backend workflows select GitHub environment `PROD`, create an environment
file from GitHub secrets, upload it to the DigitalOcean server, and pass those
settings to Docker Compose when the container starts. The declared backend image
build does not inject these secrets.

Read-only GitHub metadata confirms `DATABASE_URL`, `JWT_SECRET`,
`STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`, `INTASEND_PUB_KEY_PROD`,
`INTASEND_SECRET_KEY_PROD`, `INTASEND_CHALLENGE`, `INTASEND_WEBHOOK_SECRET`, and
the DigitalOcean SSH deployment credentials exist in `PROD`. Only secret names
and update timestamps were retrieved. Their presence does not establish live-mode
validity, webhook configuration, or the running container's current values.
`REDIS_PASSWORD`, required by the hardened release, was absent from both the
inspected `PROD` and repository secret lists. With the user's explicit approval,
a new cryptographically random value was stored in GitHub `PROD` during release
preparation. No value was printed or saved locally. Running services have not
changed; the release supplies this value to Redis and the backend together.

The release branch also adds a read-only inspection mode to the existing manual
backend workflow, allowing the stored GitHub SSH credential to inspect the
running container. Website rollout now follows successful backend deployment
from the same tested commit and uses an immutable image digest with rollback.
The migration audit now compares actual migration names, including nonstandard
filenames and shared timestamps; all nine deployment/audit tests passed after
this correction. No new schema migration is introduced by the launch fixes.

The first published inspection run confirmed that GitHub `PROD` points to
`paykey-db-do-user-18876815-0.d.db.ondigitalocean.com:25060/defaultdb`, that the
Stripe key uses a live-key prefix and that the JWT minimum length and webhook
secret format checks pass. These checks establish configured values, not provider
acceptance or the running database connection. The server also rejected the
GitHub `DO_SSH_KEY` with a public-key authentication failure. Restore authorized
SSH access before deployment; the inspection did not reach Docker or PostgreSQL.
Another 1Password CLI authorization request timed out, leaving backup inspection
unverified. The release is prepared in PR #4 and has not been deployed.

1. **Complete runtime and database verification.** DigitalOcean inventory is now
   confirmed. Existing local SSH identities were rejected by the production host;
   further 1Password CLI authorization is needed for API/database checks. Confirm
   the authorized shell access method, container image and actual database hostname. Verify
   trusted sources, managed backup retention and a successful restore into a
   separate database. Rehearse the release migrations against that restore.
2. **Configure and accept real paid billing.** Stripe and IntaSend credential names
   are confirmed in GitHub `PROD`; verify they contain the correct live credentials
   and match the signed webhook/callback configuration. Verify a controlled subscription purchase,
   activation, duplicate delivery, renewal/failure and cancellation. Confirm the
   server-defined USD prices match the approved commercial offering. Rotate the
   IntaSend challenge because historical customer-facing metadata could expose it.
3. **Complete customer distribution and notifications.** Set approved Android/iOS
   store or beta links, install signing/Firebase secrets, produce signed binaries
   and verify real-device login, payslips, downloads and notifications. Configure
   actual email/SMS providers for offered delivery channels. Store-distributed
   mobile checkout remains disabled pending the chosen distribution/payment path.
4. **Deploy and verify the hardened release.** Apply the configured
   `REDIS_PASSWORD` consistently to Redis and the backend. Release only after the above
   prerequisites and CI gates pass. Preserve old private files, remove cached
   public copies of sensitive URLs, verify testing routes are absent, run the
   read-only audit, and confirm health, tenant isolation and checkout on the
   deployed image. Code rollback does not reverse database migrations.

Use [the release runbook](../../../deploy/PRODUCTION_RELEASE.md) for operational
steps and [the mobile checklist](../../../mobile/RELEASE_CHECKLIST.md) for signing
and device acceptance. Production has not been certified launch-ready by local
tests alone.
