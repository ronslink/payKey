# Paydome Play Console preparation — 18 September 2026

Production release **1.1.6 (23)** has been uploaded and saved in
[Publishing overview](https://play.google.com/console/u/0/developers/8116066215402135719/app/4972329132643212851/publishing).
It has not been sent for review or published. Managed publishing remains on.
The existing production country selection is Kenya. Internal testing still
serves 22 (1.1.5).

## Bundle and permission correction

Play initially blocked review with “Use alternative system pickers for photos /
videos”, identifying version code 16 and requiring the permissions to be removed
from affected tracks. The prepared build 23 also inherited broad media access
from `open_filex`. Its Android manifest now explicitly removes
`READ_MEDIA_IMAGES`, `READ_MEDIA_VIDEO`, `READ_MEDIA_AUDIO` and
`READ_EXTERNAL_STORAGE`.

The existing photo and document flows use system pickers. Downloaded documents
are opened from app-private temporary storage using FileProvider. No picker
dependency or flow was replaced. Inspection of both the resulting bundle and
merged manifest confirms these broad permissions are absent. Foreground location,
camera and notifications remain as before.

- Artifact: `mobile/build/release-candidates/paydome-1.1.6-23.aab`
- Package: `com.payglobus.paydome`; version 1.1.6 (23); target SDK 36; minimum 24.
- Bytes: 64,053,685.
- SHA-256: `7464F385C292757FCCE0C3C838E4FB9FC318DF6B7618AC05691E0F05E3B4E7A6`.
- Signed build, bundletool validation and signature checks pass; the upload
  certificate matches Play. No recognized private-credential markers were found
  in 1,333 archive entries.
- Play accepted the upload and showed “Ready to release” in the bundle preview.
  This is not approval of the app's policies or production services.
- English (US) and Traditional Chinese release notes were saved. The user chose
  English (US) as the primary store language. The user then selected a language in
  the editor and asked to continue with common text assets; the editor currently
  labels that draft English (UK). Confirm the final locale before publication.
  App name, short description and full description have been saved in the draft.
  The existing 512×512 icon, 1024×500 feature graphic and three portrait phone
  screenshots were reused from the asset library and saved successfully. These
  listing changes remain unpublished.
  The editor's Next button initially did nothing. After confirming Save as draft
  succeeded and reloading the page, Next opened Step 2: Review with all assets
  intact. No tablet screenshots were required to advance. The listing is left
  on that review step; its final Save has not yet been clicked.

Subsequent Console inspection found the listing changes saved in Publishing
overview. The remaining photo/video-policy warning identifies bundle 16 (2.0.3),
which Bundle explorer maps to one active Open testing release. Its track summary
also reports 16 as the latest release. A new Open testing release 1.1.6 (23) was
created from the existing bundle library, explicitly excluding 16, and saved to
Publishing overview for review. Play showed no device-coverage loss and confirmed
the change was saved. It has not been submitted or published. Quick checks restarted.

After saving that replacement, the Photo and video permissions page's affected
bundle list contained only 22 (1.1.5), on Internal testing. Version 16 was absent.
Closed Alpha is paused/inactive on 14 (2.0.1) and was absent from that affected
list; it was not resumed or changed.

An Internal testing draft 1.1.6 (23) is saved, excludes 22, and passes the release
preview with no device-coverage loss. Its final button is **Save and publish**
and explicitly publishes immediately, unlike the production/open-testing Save.
It was not clicked because the matching hardened backend is not yet deployed.
Automatic approval review blocked an attempted temporary pause of the old
internal track because it interrupts tester access and needed explicit user
authorization. Approval was requested; the pause has not occurred.

The fresh quick checks subsequently finished successfully: Publishing overview
now says **“Your changes can now be sent for review”** and enables Submit 7 changes
for review, with no issue banner. The original version-16 submission blocker is
cleared without using Proceed anyway. The pause is no longer needed to clear
that blocker, and the user was told to disregard that request for now. Internal
testing still serves 22, so its affected-permission entry remains a separate
cleanup item; the prepared 23 draft can replace it after backend readiness.
No review submission or publication was performed.

The verification JSON records the build's base commit and the uncommitted
manifest change. Do not reuse version code 23 for a different future upload.

## Data disclosures and account deletion

All 11 existing declarations were marked actioned, but review found omissions.
The following corrections are saved as a **Data safety draft**, not submitted:

- Approximate and precise foreground attendance location: collected and shared
  with the associated employer, stored rather than processed ephemerally,
  optional to overall app use, for app functionality.
- Device/installation and push-token identifiers: collected, stored, required
  under the current implementation, for app functionality, analytics and
  developer communications. Notification display permission does not disable
  identifier collection.
- Partial-data deletion while preserving the account: changed from Yes to No.
  The existing feature requests account deletion.

Promotional push use at launch is awaiting the user's answer. The code contains
campaign functionality. If it will be used, add Advertising or marketing to the
identifier purpose before finalizing the declaration. No campaign was sent.

The source privacy policy now explains these data flows, user-selected photos
and documents, Firebase diagnostics, employer access and permission controls.
It does not invent retention durations. The source deletion page now uses the
authenticated owner endpoint for signed-in users, preserves password-based public
requests, and directs Google/Apple users without a website session to support
for ownership verification. Unsupported timing and automatic-completion promises
were removed. These website changes are not yet deployed.

Six focused deletion tests cover ownership, password/public requests, authenticated
passwordless requests, expired sessions, billing errors and missing confirmation.
Focused lint and the combined website TypeScript/Vite production build pass.
All 15 discovered website tests pass (nine billing and six deletion). The release
workflow runs this test command. No real deletion was requested.

Google's validator repeatedly reported **403** for
`https://paydome.co/deleteme`. An anonymous HTTP request and the in-app browser
loaded it successfully (HTTP 200 via Cloudflare), so the discrepancy remains
unresolved. Cloudflare request filtering is a hypothesis, not a verified cause.
Inspect the relevant edge event/rule before changing it; do not weaken API or
account-deletion protections. Repository SPA routing contains no blocking rule.

Reviewer credentials and instructions are already configured in Play, including
the assertion of access to paid features. They were not changed or printed.
Their current ability to access the signed release still needs verification.

## Steps before submission and launch

1. Finish Google's automated checks for the saved production release. Resolve
   any remaining old-bundle permission issue across affected tracks. Do not use
   “Proceed anyway” to bypass the reported permission defect.
2. Finish the US English default-language change, finalize truthful data-safety
   answers, deploy the matching privacy/deletion pages, and resolve Google's 403.
3. Deploy and verify the matching hardened backend and website. Preserve the
   uncommitted M-Pesa subscription work from the original launch task and finish
   its review/CI before merging. Main deploys automatically after passing CI.
4. Resolve the existing Stripe-to-IntaSend payroll-wallet funding gap or gate
   card wallet funding. This bundle exposes the card option. Subscription billing
   is separate. Complete provider callback and signed-device acceptance, including
   reviewer login and system photo/document pickers.
5. Send the intended production change and corrected declarations for Google
   review. Existing unrelated pending changes resume open testing and pause closed
   testing; inspect them before submitting or publishing a combined batch.
6. After approval and service readiness, publish through managed publishing.

The earlier release runbook retains the remaining provider, database-protection
and notification requirements. This preparation does not establish that the app
is live or that payments work against real providers.
