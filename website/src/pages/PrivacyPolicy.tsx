export default function PrivacyPolicy() {
    return (
        <div className="min-h-screen pt-16">
            <main className="py-16 sm:py-24">
                <div className="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8">

                    <h1 className="text-3xl sm:text-4xl font-bold text-white mb-2">Privacy Policy</h1>
                    <p className="text-slate-400 mb-12">Last updated: {new Date().toLocaleDateString()}</p>

                    <div className="flex flex-col gap-10 text-slate-300 leading-relaxed">

                        <section>
                            <h2 className="text-xl font-semibold text-white mb-4">1. Introduction</h2>
                            <p>
                                Welcome to Paydome. We are committed to protecting your personal information and your right to privacy.
                                This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you visit our website
                                or use our mobile application.
                            </p>
                            <p className="mt-4">
                                Paydome is a subsidiary of PayGlobus GmbH. By accessing or using our Service, you signify that you have read, understood,
                                and agree to our collection, storage, use, and disclosure of your personal information as described in this Privacy Policy.
                            </p>
                        </section>

                        <section>
                            <h2 className="text-xl font-semibold text-white mb-4">2. Information We Collect</h2>
                            <p>
                                We collect information that identifies, relates to, describes, references, is capable of being associated with, or could
                                reasonably be linked, directly or indirectly, with a particular consumer or device ("personal information").
                            </p>
                            <ul className="list-disc pl-6 mt-4 flex flex-col gap-2">
                                <li><strong className="text-white">Personal Identifiers:</strong> Name, email address, phone number, postal address.</li>
                                <li><strong className="text-white">Employment Data:</strong> Employer details, job role, salary information (for payroll processing).</li>
                                <li><strong className="text-white">Financial Information:</strong> Bank account details, tax identification numbers.</li>
                                <li><strong className="text-white">Usage Data:</strong> Information on how you use our website and mobile app, including IP address, browser type, and operating system.</li>
                            </ul>
                        </section>

                        <section>
                            <h2 className="text-xl font-semibold text-white mb-4">3. How We Use Your Information</h2>
                            <p>We use the information we collect to:</p>
                            <ul className="list-disc pl-6 mt-4 flex flex-col gap-2">
                                <li>Provide, operate, and maintain our payroll services.</li>
                                <li>Process your transactions and manage your account.</li>
                                <li>Improve, personalize, and expand our website and services.</li>
                                <li>Understand and analyze how you use our services.</li>
                                <li>Communicate with you, either directly or through one of our partners, including for customer service, updates, and marketing.</li>
                                <li>Process payments and tax filings on your behalf.</li>
                                <li>Find and prevent fraud.</li>
                            </ul>
                        </section>

                        <section>
                            <h2 className="text-xl font-semibold text-white mb-4">4. Sharing Your Information</h2>
                            <p>
                                We may share your information with third parties in certain situations, including:
                            </p>
                            <ul className="list-disc pl-6 mt-4 flex flex-col gap-2">
                                <li><strong className="text-white">Service Providers:</strong> We may share your data with third-party vendors, service providers, contractors, or agents who perform services for us or on our behalf and require access to such information to do that work.</li>
                                <li><strong className="text-white">Business Transfers:</strong> We may share or transfer your information in connection with, or during negotiations of, any merger, sale of company assets, financing, or acquisition of all or a portion of our business to another company.</li>
                                <li><strong className="text-white">Legal Requirements:</strong> We may disclose your information where we are legally required to do so in order to comply with applicable law, governmental requests, a judicial proceeding, court order, or legal process.</li>
                            </ul>
                        </section>

                        <section>
                            <h2 className="text-xl font-semibold text-white mb-4">5. Security of Your Information</h2>
                            <p>
                                We use administrative, technical, and physical security measures to help protect your personal information.
                                While we have taken reasonable steps to secure the personal information you provide to us, please be aware that despite our efforts,
                                no security measures are perfect or impenetrable, and no method of data transmission can be guaranteed against any interception or other type of misuse.
                            </p>
                        </section>

                        <section>
                            <h2 className="text-xl font-semibold text-white mb-4">6. Contact Us</h2>
                            <p>
                                If you have questions or comments about this Privacy Policy, please contact us at:
                            </p>
                            <div className="mt-4 p-6 bg-white/5 rounded-xl border border-white/10">
                                <p className="font-semibold text-white">Paydome Support</p>
                                <p className="mt-1">Email: support@paydome.co</p>
                                <p className="mt-1">Address: PayGlobus GmbH, Lange Str. 13, 71686 Remseck am Neckar, Germany</p>
                            </div>
                        </section>

                    </div>
                </div>
            </main>
        </div>
    );
}
