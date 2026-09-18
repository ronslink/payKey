# Launch gate implementation — 18 September 2026

These changes are prepared in PR #4 and have not been merged or deployed. The
original production assessment remains a snapshot before these fixes; the
verified runtime findings below supersede its unresolved access/database checks.
Paid subscriptions are required for launch; the customer billing path is the
website account flow and Stripe hosted checkout.

## Implemented

| Gate | Change |
| --- | --- |
| Public destructive routes | Testing routes load only in the test environment. Public registration rejects privileged fields; users start with the server-assigned role, free tier and zero balances. |
| Authentication | Production JWT configuration fails closed. Social login requires verified provider tokens and configured audiences. |
| Payment integrity | Live IntaSend callbacks cannot bypass verification. Settlement handles repeated clearing/final callbacks without duplicate balance movements. Provider secrets are removed from stored and returned callback metadata. |
| Paid launch | Website signup/login, authenticated plan selection, server-priced USD checkout and renewal controls are implemented. A return page reports active service only after backend verification. Signed Stripe callbacks settle once per invoice, handle out-of-order events and protect cancellation/renewal periods. Existing Stripe contracts cannot be overwritten by another payment method. Production requires live Stripe credentials. |
| Wallet currency and ledger | KES remains the default. EUR uses a separate empty input and explicit EUR payment request, then converts to KES on verified settlement. Invalid/missing FX prevents credit; replayed callbacks credit once. Hourly IntaSend observations report discrepancies without overwriting the ledger. The provider funding gap below still blocks EUR release. |
| Private files | Worker documents, government payroll files and accounting exports use persistent private storage and authenticated ownership checks. Existing file references resolve through preserved legacy storage. Public static serving is limited to avatar images. |
| Database safety | Production requires an explicit database URL and verified TLS. Schema synchronization and automatic startup migrations are disabled in production. A standalone read-only audit identifies the actual database host, TLS session and migration state without starting the app. |
| Deployment | A shared CI path tests before publishing an immutable image. Release scripts preserve uploads/exports and previous containers, reuse Redis storage, reject pending migrations before stopping the old app, and require database/Redis readiness before promoting configuration. |
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

The last mile still requires **Stripe sandbox checkout with signed webhook
delivery and acceptance on a device using the signed build**. Browser mocks and
unit tests alone cannot establish those outcomes. Monitor the first genuine,
authorized live purchase; do not create synthetic live-card transactions for
testing, as required by [Stripe's testing guidance](https://docs.stripe.com/testing).

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
- Backend production container built successfully with Node 24. Nine deployment
  configuration/audit tests passed. Backend lint comparison reports zero added
  diagnostics; existing debt remains visible. The two final journey files also
  pass focused lint.
- Subsequent wallet fixes passed three PostgreSQL settlement tests: explicit EUR
  and exact cents, retryable FX failure with concurrent callback idempotency, and
  mismatched/unpaid payment rejection. One widget regression preserves separate
  KES/EUR inputs; one reconciliation regression preserves other-provider credit
  when IntaSend reports a lower balance. Nine configuration checks and the backend
  build passed. The lint baseline reports zero introduced diagnostic fingerprints;
  existing debt remains. These local results require fresh CI for the updated source.
- Android now uses `FlutterFragmentActivity` and AppCompat themes as required by
  [the Stripe Flutter SDK](https://github.com/flutter-stripe/flutter_stripe).
  The mobile API consumes only the validated publishable key and PaymentIntent
  client secret; server secret keys are not returned. The signed Android rebuild
  with these changes succeeded and passed bundletool, signature and upload-certificate
  verification. A scan of its 1,333 entries found no recognized private-secret markers.

No production deployment or provider transaction was performed. No claim of
current statutory-rate compliance or live mobile-store approval is made by these
local workflow checks.

## Verified production state

Read-only DigitalOcean API queries authenticated with the personal token held
in 1Password confirmed the following inventory. The token was injected into a
subprocess without printing it or saving it in the repository or doctl configuration.

| Resource | Verified state |
| --- | --- |
| Droplet `paykey-prod` (`539164900`) | Active, London `lon1`, public `46.101.95.200`, private `10.106.0.2`. |
| Managed cluster `paykey-db` (`2372047b-149b-4507-a640-6b456fa9a1d6`) | Online, PostgreSQL 17, `lon1`, one node, `db-s-1vcpu-1gb`. |
| Public website and `/countries` API | Both returned HTTP 200 on the follow-up check. |
| Public `/health/ready` | HTTP 404; the newly implemented readiness endpoint is not available on the current deployment. |

The user restored authorization for the existing deployment key. Local SSH and
the [GitHub production inspection](https://github.com/ronslink/payKey/actions/runs/35336679803)
now succeed. A read-only probe executed inside the running backend confirmed:

| Runtime check | Verified state |
| --- | --- |
| Actual PostgreSQL connection | `paykey-db-do-user-18876815-0.d.db.ondigitalocean.com:25060/defaultdb`; certificate verification enabled, TLS 1.3, session read-only. |
| Migration ledger | All 35 compiled migration names match all 35 applied names; no pending or extra migrations. No SQL is required for this application release. |
| Database CA | Installed on the host and mounted read-only. |
| Backend and Redis | Healthy; Redis retains the persistent `deploy_redis_data_prod` volume. Approximately 29 GiB of disk space is free. |
| Running backend image | `sha256:a80bb94c7efba3873e1d26911de297608a1b18ef22724b7bbd5858c3a91f759c`; no revision label, so the deployed source commit is not established. |
| Stripe account and subscription endpoint | Live account authentication, charges/payouts enabled and card payments active verified read-only. The enabled endpoint `https://api.paydome.co/payments/subscriptions/webhook` includes all five subscription lifecycle events. Matching the configured signing secret still requires actual signed delivery. |
| Notification configuration | Email and SMS use `MOCK`; live delivery is not established. |

Managed backup freshness/retention and database trusted-source controls remain
unverified because subsequent 1Password CLI authorization requests timed out.
The successful runtime probe resolves the earlier SSH and database-identity
blockers. These inspections changed no database records, firewall rules or
running services.

The connected Vercel account
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
and update timestamps were retrieved in that metadata check. Their presence alone
does not establish provider acceptance; the separate runtime checks are listed above.
`REDIS_PASSWORD`, required by the hardened release, was absent from both the
inspected `PROD` and repository secret lists. With the user's explicit approval,
a new cryptographically random value was stored in GitHub `PROD` during release
preparation. No value was printed or saved locally. Running services have not
changed; the release supplies this value to Redis and the backend together.
The existing live `STRIPE_PUBLISHABLE_KEY` was copied from the local production
configuration to the GitHub `PROD` variable of that name and verified without
printing its value. The release workflow, environment writer and Compose require
and pass it at runtime; this public key does not replace the server secret key.

The release branch also adds a read-only inspection mode to the existing manual
backend workflow, allowing the stored GitHub SSH credential to inspect the
running container. Website rollout now follows successful backend deployment
from the same tested commit and uses an immutable image digest with rollback.
The migration audit now compares actual migration names, including nonstandard
filenames and shared timestamps; all nine deployment/audit tests passed after
this correction. No new schema migration is introduced by the launch fixes.

Android **1.1.6 (version code 23)** was rebuilt with Flutter 3.41.7 for
`com.payglobus.paydome` after the wallet and native SDK fixes. The earlier candidate
and rebuilt artifact both passed bundletool/signature checks. The
signed-in Play Console confirms that **22 (1.1.5)** is available on the internal
testing track and production is inactive. Build 23 has not been uploaded or
published. The registered Play upload certificate matches the local AAB's SHA-256
fingerprint exactly: `FE:9C:82:E1:64:67:F4:46:29:21:63:48:69:D4:23:69:68:8D:FF:F1:1B:45:17:4D:C7:1E:02:EE:73:76:65:DE`.
Deploy the matching backend before mobile rollout, then complete acceptance on a
device using the signed build.

### Pull request checks and triage

For the earlier PR #4 head `e75e077`, [functional backend CI](https://github.com/ronslink/payKey/actions/runs/35336199060)
passed its build, lint-regression, unit/security, deployment-configuration and
isolated-database E2E checks. Image publication and deployment were skipped for
the pull request. CodeQL also passed for this head. The migration-identity parser
and storage-path containment corrections remain covered. These results do not
establish live provider or signed-device acceptance.
The subsequent wallet, native SDK and reconciliation changes need fresh CI;
the earlier passing run does not cover them.

SonarCloud's check remains failed only on New Code Security Rating. The earlier
payslip-test sort reliability finding is resolved by an explicit `localeCompare`
comparator. Its remaining security findings
cover action version pinning, package installation scripts, the container's root
user, `git` lookup through `PATH` in the optional baseline generator, and the
local environment-writer's operator-supplied destination argument. They remain
open for contextual security review; no alerts were dismissed, no gate was
disabled, and no application permissions or CLI behavior were changed merely to
improve the rating. The local CLI finding does not demonstrate a customer-facing
path traversal. Package-install and runtime-user changes require dependency and
storage-permission analysis before being applied.

Successful functional CI is not a claim that every quality check passed. The
SonarCloud findings remain open for review alongside the production gates below.

## Remaining production gates

1. **Verify database protection.** Confirm trusted-source controls and managed
   backup freshness/retention. Runtime identity, TLS and the migration ledger are
   verified. No migration or restore rehearsal is needed for this application-only
   rollout; if later work introduces pending SQL, review it and rehearse it against
   a restored separate database before applying it.
2. **Accept paid billing through the provider.** Stripe account authentication and
   the enabled subscription endpoint are verified; establish checkout, actual
   signed delivery, activation and cancellation through Stripe sandbox, including
   retry and renewal/failure handling. Monitor the first genuine authorized live
   purchase instead of making a synthetic live-card test charge. Verify the live signing-secret match through actual
   delivery, IntaSend callback configuration and the approved server-defined USD
   prices. Rotate the IntaSend challenge because historical customer-facing
   metadata could expose it.
3. **Resolve EUR payroll funding before release.** Stripe credits the application's
   local KES ledger, but payroll pays from each employer's IntaSend working wallet.
   No transfer/funding bridge exists. Removing hourly ledger overwrites preserves
   the credit; it does not fund payroll. The operational choice is still pending:
   pre-funded float, manual settlement, or funding not yet set up. Keep EUR payments
   blocked from release until this is agreed and verified. The Paydome webhook is
   missing `payment_intent.succeeded`; add that event only after the corrected
   backend is deployed and the funding path is agreed. Do not enable event delivery
   as a substitute for resolving provider funding.
4. **Complete customer distribution and notifications.** Set approved store or
   beta links and verify real-device login, payslips, downloads and notifications
   using the signed Android candidate. Android signing is verified locally;
   automated signing/Firebase setup and any iOS release remain separate work.
   Configure actual email/SMS providers for offered delivery channels. Store-distributed
   mobile subscription checkout remains disabled pending the chosen distribution/payment path.
5. **Deploy and verify the hardened release.** Apply the configured
   `REDIS_PASSWORD` consistently to Redis and the backend. Release only after the above
   prerequisites and CI gates pass. Preserve old private files, remove cached
   public copies of sensitive URLs, verify testing routes are absent, run the
   read-only audit, and confirm health, tenant isolation and checkout on the
   deployed image. Code rollback does not reverse database migrations.

Use [the release runbook](../../../deploy/PRODUCTION_RELEASE.md) for operational
steps and [the mobile checklist](../../../mobile/RELEASE_CHECKLIST.md) for signing
and device acceptance. Production has not been certified launch-ready by local
tests alone.
