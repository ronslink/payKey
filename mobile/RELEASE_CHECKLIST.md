# Mobile release candidates

The 18 September 2026 Android candidate is **1.1.6 (version code 23)**, following
the user's confirmed latest Play upload, version code 22. The package is
`com.payglobus.paydome`. The signed rebuild with the card-routing/native fixes succeeded;
the rebuilt artifact passed bundletool and jarsigner checks, and its upload
certificate exactly matches Play Console. Its 1,333 archive entries contained no
recognized private-secret markers. After removing unnecessary plugin-inherited
media/storage permissions, the AAB is 64,053,685 bytes with SHA-256
`7464F385C292757FCCE0C3C838E4FB9FC318DF6B7618AC05691E0F05E3B4E7A6`.
The packaged manifest contains no `READ_MEDIA_*` or external-storage permissions.
Existing photo/document selection uses system pickers; downloaded files are
opened from app-private storage. Verify these flows on a physical device.
Play currently shows **22 (1.1.5)** on internal testing and production inactive.
Play accepted the corrected bundle into production release `1.1.6 (23)` on
18 September 2026. The release is saved in Publishing overview, not submitted
for review or published. Google's automated checks and review remain separate.

Play Console's publishing overview identifies broad photo/video permissions in
version code 16 as a review blocker and requires correction across affected
tracks. The corrected build 23 removes those permissions; older affected bundles
must also be replaced or removed from active release tracks before submission.
Kenya is already the targeted production country, managed publishing is on, and
reviewer sign-in details are configured. The existing ready-to-publish change is
a closed-testing track pause, not a production release.

Deploy and verify the matching backend before rolling this mobile candidate out:
its authenticated document/download flows depend on the hardened API. Then
perform the physical-device checks below. This bundle is uploaded but has not
been published to Google Play.

M-Pesa/KES is the default top-up method. Cards use Stripe with explicit KES by
default or optional EUR. EUR uses a separate empty amount field; verified
settlement converts it to the KES ledger. Five focused mobile checks cover routing,
currency preservation and Stripe native initialization; focused analysis passes.
Android now uses `FlutterFragmentActivity`
and AppCompat themes required by [the Stripe Flutter SDK](https://github.com/flutter-stripe/flutter_stripe).
The backend supplies the validated public Stripe key and PaymentIntent client
secret; the app must never receive the server secret key.

**Stripe wallet release is blocked pending actual payroll funding.** Stripe funds
do not automatically reach the employer's IntaSend working wallet, which pays
payroll. The app's ledger credit and its new observation-only reconciliation do
not provide those funds. The owner must establish pre-funded float/manual
settlement or another verified funding arrangement before KES/EUR card rollout.
Stripe subscription billing remains separate from payroll wallet funding. The
missing `payment_intent.succeeded` webhook event must be added only after the
corrected backend is deployed and that funding path is agreed.

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
