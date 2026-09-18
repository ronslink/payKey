export default function PrivacyPolicy() {
  return (
    <div className="min-h-screen pt-16">
      <main className="py-16 sm:py-24">
        <div className="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8">
          <h1 className="text-3xl sm:text-4xl font-bold text-white mb-2">
            Privacy Policy
          </h1>
          <p className="text-slate-400 mb-12">Last updated: 18 September 2026</p>

          <div className="flex flex-col gap-10 text-slate-300 leading-relaxed">
            <section>
              <h2 className="text-xl font-semibold text-white mb-4">
                1. Introduction
              </h2>
              <p>
                This notice explains how Paydome collects, uses, shares, and
                protects personal data when you use our website, mobile
                application, and payroll services. Paydome is a PayGlobus
                product, and PayGlobus GmbH is the contact for this notice.
              </p>
              <p className="mt-4">
                Employers may add information about their workers to Paydome.
                Employers are responsible for having an appropriate basis to
                provide that information and for keeping it accurate.
              </p>
            </section>

            <section>
              <h2 className="text-xl font-semibold text-white mb-4">
                2. Information We Collect
              </h2>
              <ul className="list-disc pl-6 flex flex-col gap-2">
                <li>
                  <strong className="text-white">
                    Account and contact data:
                  </strong>{" "}
                  names, email addresses, phone numbers, and account settings.
                </li>
                <li>
                  <strong className="text-white">Employment data:</strong>{" "}
                  employer and worker details, job information, salary,
                  benefits, deductions, attendance, and payroll records.
                </li>
                <li>
                  <strong className="text-white">Attendance location:</strong>{" "}
                  approximate or precise coordinates, depending on your device
                  permission, when you use foreground clock-in, clock-out, and
                  workplace geofence features. We store recorded clock-in and
                  clock-out coordinates as part of attendance records linked to
                  the worker and employer.
                </li>
                <li>
                  <strong className="text-white">Photos and documents:</strong>{" "}
                  photos you choose to take or upload, and documents or import
                  files you select for account, worker, or payroll features.
                </li>
                <li>
                  <strong className="text-white">Payment data:</strong> payment
                  method details, account or mobile-money identifiers,
                  transaction references, status, and amounts. Payment providers
                  may collect additional information under their own privacy
                  notices.
                </li>
                <li>
                  <strong className="text-white">
                    Government identifiers:
                  </strong>{" "}
                  information such as KRA PIN, NSSF number, and SHIF number when
                  you choose to record it.
                </li>
                <li>
                  <strong className="text-white">
                    App installation and notification data:
                  </strong>{" "}
                  Firebase installation identifiers, push notification
                  registration tokens, device platform, and the account linked
                  to a notification registration. Firebase Cloud Messaging uses
                  these identifiers to deliver push notifications.
                </li>
                <li>
                  <strong className="text-white">
                    Usage and diagnostic data:
                  </strong>{" "}
                  device, browser, IP address, logs, crash details, and how you
                  use the service. Firebase Crashlytics processes crash reports,
                  app and device diagnostics, and installation identifiers to
                  help us diagnose faults.
                </li>
              </ul>
            </section>

            <section>
              <h2 className="text-xl font-semibold text-white mb-4">
                3. How We Use Information
              </h2>
              <ul className="list-disc pl-6 flex flex-col gap-2">
                <li>Provide, secure, support, and improve Paydome.</li>
                <li>Manage accounts and authenticate users.</li>
                <li>
                  Calculate payroll deductions and produce records that support
                  employer filing and record-keeping obligations.
                </li>
                <li>
                  Record attendance and check whether a worker is at or has left
                  a configured workplace location.
                </li>
                <li>
                  Initiate and track payments that a user authorizes through our
                  payment providers.
                </li>
                <li>Respond to support requests and service communications.</li>
                <li>
                  Where we run in-app or push campaigns, send information about
                  Paydome features, plans, or promotions.
                </li>
                <li>Detect fraud, abuse, security incidents, and errors.</li>
                <li>Meet legal, accounting, and regulatory obligations.</li>
              </ul>
            </section>

            <section>
              <h2 className="text-xl font-semibold text-white mb-4">
                4. When We Share Information
              </h2>
              <p>We may share data only as needed with:</p>
              <ul className="list-disc pl-6 mt-4 flex flex-col gap-2">
                <li>
                  the employer associated with a worker, including attendance
                  records and recorded clock-in and clock-out coordinates;
                </li>
                <li>
                  payment providers and financial institutions used to process
                  or reconcile user-authorized transactions;
                </li>
                <li>
                  hosting, database, authentication, analytics, communications,
                  and technical-support providers, including Google Firebase for
                  push notifications and crash diagnostics;
                </li>
                <li>
                  professional advisers, auditors, insurers, and authorities
                  when required to protect rights or comply with law; and
                </li>
                <li>
                  a buyer or successor in connection with a proposed or
                  completed business transaction, subject to appropriate
                  safeguards.
                </li>
              </ul>
              <p className="mt-4">
                We do not sell personal data. We do not authorize service
                providers to use payroll data for their own marketing.
              </p>
            </section>

            <section>
              <h2 className="text-xl font-semibold text-white mb-4">
                5. Retention
              </h2>
              <p>
                We retain account and payroll data while it is needed to provide
                the service and for applicable legal, tax, accounting, dispute,
                fraud-prevention, and security requirements. When data is no
                longer needed, we delete or anonymize it, subject to reasonable
                backup and legal-hold periods.
              </p>
            </section>

            <section>
              <h2 className="text-xl font-semibold text-white mb-4">
                6. International Processing
              </h2>
              <p>
                PayGlobus GmbH and some service providers may process data
                outside Kenya. Where personal data is transferred
                internationally, we use safeguards required by applicable
                data-protection law and limit access to the purposes described
                in this notice.
              </p>
            </section>

            <section>
              <h2 className="text-xl font-semibold text-white mb-4">
                7. Your Choices and Rights
              </h2>
              <p>
                Subject to applicable law, you may ask to be informed about our
                use of your data, access it, correct inaccurate data, object to
                or restrict processing, request deletion, or request a portable
                copy. Where processing relies on consent, you may withdraw that
                consent.
              </p>
              <p className="mt-4">
                You can decline or revoke location permission in your device
                settings and continue using other Paydome features. Attendance
                actions that need your location, including checks for configured
                workplace geofences, may then be unavailable. Revoking permission
                does not remove coordinates already stored in attendance records.
              </p>
              <p className="mt-4">
                You choose which photos and documents to provide. You can also
                control whether notifications are displayed through your device
                settings. Turning off notification display does not by itself
                stop Firebase installation identifiers or notification
                registration tokens from being created and collected.
              </p>
              <p className="mt-4">
                You can start an account-deletion request on our{" "}
                <a
                  href="/deleteme"
                  className="text-emerald-400 hover:text-emerald-300"
                >
                  Delete My Data page
                </a>{" "}
                or email us. We may need to verify your identity and may retain
                limited information where the law requires it.
              </p>
            </section>

            <section>
              <h2 className="text-xl font-semibold text-white mb-4">
                8. Security
              </h2>
              <p>
                We use administrative, technical, and organizational measures
                designed to protect personal data. No storage or transmission
                method is completely secure, so we cannot guarantee absolute
                security.
              </p>
            </section>

            <section>
              <h2 className="text-xl font-semibold text-white mb-4">
                9. Contact Us
              </h2>
              <p>Contact us with privacy questions, complaints, or requests:</p>
              <div className="mt-4 p-6 bg-white/5 rounded-xl border border-white/10">
                <p className="font-semibold text-white">
                  Paydome / PayGlobus GmbH
                </p>
                <p className="mt-1">
                  Email:{" "}
                  <a
                    href="mailto:support@paydome.co"
                    className="text-emerald-400 hover:text-emerald-300"
                  >
                    support@paydome.co
                  </a>
                </p>
                <p className="mt-1">
                  Address: Lange Str. 13, 71686 Remseck am Neckar, Germany
                </p>
              </div>
            </section>
          </div>
        </div>
      </main>
    </div>
  );
}
