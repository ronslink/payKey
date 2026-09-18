# Mobile release candidates

The manual Android workflow builds a signed production AAB; it does not publish
to Google Play. Set these secrets in the GitHub `PROD` environment:

- `GOOGLE_SERVICES_JSON_BASE64`: Firebase configuration matching `com.payglobus.paydome`.
- `ANDROID_KEYSTORE_BASE64`: the existing Play upload keystore (preserve the signing identity).
- `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`, `ANDROID_KEYSTORE_PASSWORD`.

Run **Android Production Release Artifact** with a `build_number` greater than
the last uploaded Play version code. The workflow validates configuration, runs
analysis/tests, builds an AAB, and removes temporary signing files. Download the
artifact for internal testing and store review. Flutter is pinned to 3.41.7.

The GitHub iOS workflow is explicitly an **unsigned compile check**, not an
installable App Store release. Supply `GOOGLE_SERVICE_INFO_PLIST` as base64 in
`PROD`, matching `com.paykey.app`. Use the existing Xcode Cloud configuration to
produce signed archives, then verify TestFlight installation and App Store
submission. Signing and publication status remain external release checks.

Both GitHub builds explicitly target `APP_ENV=prod` and
`API_URL=https://api.paydome.co`. Native external subscription checkout remains
disabled. Never embed payment secret keys in a mobile build. Web account billing
does not establish approval for steering or purchasing in either mobile store.

Before distribution, test a production-configured signed build on a physical
device: login/registration, notification permission and account switching,
employee own-payslip download, authenticated worker documents, and normal payroll
operations using controlled test data. Verify production provider/webhook setup
separately; a passing compile check does not prove production payment readiness.
