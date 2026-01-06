import { Header } from '../components/Header';
import { Footer } from '../components/Footer';

export default function PrivacyPolicy() {
    return (
        <div style={{ minHeight: '100vh', display: 'flex', flexDirection: 'column' }}>
            <Header />

            <main style={{ flex: 1, paddingTop: '120px', paddingBottom: '80px', background: '#020617' }}>
                <div className="container" style={{ maxWidth: '800px' }}>

                    <h1 style={{ fontSize: '2.5rem', fontWeight: 700, marginBottom: '0.5rem' }}>Privacy Policy</h1>
                    <p style={{ color: '#94a3b8', marginBottom: '3rem' }}>Last updated: {new Date().toLocaleDateString()}</p>

                    <div style={{ display: 'flex', flexDirection: 'column', gap: '2.5rem', color: '#cbd5e1', lineHeight: 1.7 }}>

                        <section>
                            <h2 style={{ fontSize: '1.5rem', fontWeight: 600, color: 'white', marginBottom: '1rem' }}>1. Introduction</h2>
                            <p>
                                Welcome to Paydome. We are committed to protecting your personal information and your right to privacy.
                                This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you visit our website
                                or use our mobile application.
                            </p>
                            <p style={{ marginTop: '1rem' }}>
                                Paydome is a subsidiary of PayGlobus GmbH. By accessing or using our Service, you signify that you have read, understood,
                                and agree to our collection, storage, use, and disclosure of your personal information as described in this Privacy Policy.
                            </p>
                        </section>

                        <section>
                            <h2 style={{ fontSize: '1.5rem', fontWeight: 600, color: 'white', marginBottom: '1rem' }}>2. Information We Collect</h2>
                            <p>
                                We collect information that identifies, relates to, describes, references, is capable of being associated with, or could
                                reasonably be linked, directly or indirectly, with a particular consumer or device ("personal information").
                            </p>
                            <ul style={{ listStyleType: 'disc', paddingLeft: '1.5rem', marginTop: '1rem', display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
                                <li><strong>Personal Identifiers:</strong> Name, email address, phone number, postal address.</li>
                                <li><strong>Employment Data:</strong> Employer details, job role, salary information (for payroll processing).</li>
                                <li><strong>Financial Information:</strong> Bank account details, tax identification numbers.</li>
                                <li><strong>Usage Data:</strong> Information on how you use our website and mobile app, including IP address, browser type, and operating system.</li>
                            </ul>
                        </section>

                        <section>
                            <h2 style={{ fontSize: '1.5rem', fontWeight: 600, color: 'white', marginBottom: '1rem' }}>3. How We Use Your Information</h2>
                            <p>We use the information we collect to:</p>
                            <ul style={{ listStyleType: 'disc', paddingLeft: '1.5rem', marginTop: '1rem', display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
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
                            <h2 style={{ fontSize: '1.5rem', fontWeight: 600, color: 'white', marginBottom: '1rem' }}>4. Sharing Your Information</h2>
                            <p>
                                We may share your information with third parties in certain situations, including:
                            </p>
                            <ul style={{ listStyleType: 'disc', paddingLeft: '1.5rem', marginTop: '1rem', display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
                                <li><strong>Service Providers:</strong> We may share your data with third-party vendors, service providers, contractors, or agents who perform services for us or on our behalf and require access to such information to do that work.</li>
                                <li><strong>Business Transfers:</strong> We may share or transfer your information in connection with, or during negotiations of, any merger, sale of company assets, financing, or acquisition of all or a portion of our business to another company.</li>
                                <li><strong>Legal Requirements:</strong> We may disclose your information where we are legally required to do so in order to comply with applicable law, governmental requests, a judicial proceeding, court order, or legal process.</li>
                            </ul>
                        </section>

                        <section>
                            <h2 style={{ fontSize: '1.5rem', fontWeight: 600, color: 'white', marginBottom: '1rem' }}>5. Security of Your Information</h2>
                            <p>
                                We use administrative, technical, and physical security measures to help protect your personal information.
                                While we have taken reasonable steps to secure the personal information you provide to us, please be aware that despite our efforts,
                                no security measures are perfect or impenetrable, and no method of data transmission can be guaranteed against any interception or other type of misuse.
                            </p>
                        </section>

                        <section>
                            <h2 style={{ fontSize: '1.5rem', fontWeight: 600, color: 'white', marginBottom: '1rem' }}>6. Contact Us</h2>
                            <p>
                                If you have questions or comments about this Privacy Policy, please contact us at:
                            </p>
                            <div style={{ marginTop: '1rem', padding: '1.5rem', background: 'rgba(255,255,255,0.05)', borderRadius: '12px' }}>
                                <p><strong>Paydome Support</strong></p>
                                <p>Email: support@paydome.co</p>
                                <p>Address: PayGlobus GmbH, Lange Str. 13, 71686 Remseck am Neckar, Germany</p>
                            </div>
                        </section>

                    </div>
                </div>
            </main>

            <Footer />
        </div>
    );
}
