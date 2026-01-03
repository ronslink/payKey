import { Header } from '../components/Header';
import { Footer } from '../components/Footer';
import { HelpCircle, Mail, Phone } from 'lucide-react';

export default function iOSHelp() {
    return (
        <div style={{ minHeight: '100vh', display: 'flex', flexDirection: 'column' }}>
            <Header />

            <main style={{ flex: 1, paddingTop: '80px' }}>
                <section className="section">
                    <div className="container" style={{ maxWidth: '800px' }}>
                        <h1 style={{ fontSize: '2.5rem', marginBottom: '1rem' }}>Support & Help Center</h1>
                        <p style={{ fontSize: '1.25rem', color: '#94a3b8', marginBottom: '3rem' }}>
                            We're here to help you get the most out of Paydome on your iOS device.
                        </p>

                        <div style={{ display: 'grid', gap: '2rem' }}>
                            <div style={{ background: '#0f172a', padding: '2rem', borderRadius: '16px', border: '1px solid #1e293b' }}>
                                <h2 style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', marginBottom: '1rem' }}>
                                    <HelpCircle className="text-blue-500" /> FAQ
                                </h2>

                                <div style={{ display: 'grid', gap: '1.5rem' }}>
                                    <details style={{ cursor: 'pointer' }}>
                                        <summary style={{ fontWeight: 600, padding: '0.5rem 0' }}>How do I reset my PIN?</summary>
                                        <p style={{ color: '#94a3b8', marginTop: '0.5rem' }}>You can reset your PIN from the login screen by tapping "Forgot PIN". A verification code will be sent to your registered email.</p>
                                    </details>

                                    <details style={{ cursor: 'pointer' }}>
                                        <summary style={{ fontWeight: 600, padding: '0.5rem 0' }}> Is my data secure?</summary>
                                        <p style={{ color: '#94a3b8', marginTop: '0.5rem' }}>Yes, all data is encrypted using military-grade AES-256 encryption. We are fully GDPR compliant as part of the PayGlobus group.</p>
                                    </details>

                                    <details style={{ cursor: 'pointer' }}>
                                        <summary style={{ fontWeight: 600, padding: '0.5rem 0' }}>How do I export payslips?</summary>
                                        <p style={{ color: '#94a3b8', marginTop: '0.5rem' }}>Navigate to the "Documents" tab, select the month, and tap the export icon in the top right corner.</p>
                                    </details>
                                </div>
                            </div>

                            <div style={{ background: '#0f172a', padding: '2rem', borderRadius: '16px', border: '1px solid #1e293b' }}>
                                <h2 style={{ marginBottom: '1rem' }}>Contact Us</h2>
                                <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
                                    <a href="mailto:support@paydome.co" style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', color: '#94a3b8' }}>
                                        <Mail size={20} /> support@paydome.co
                                    </a>
                                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', color: '#94a3b8' }}>
                                        <Phone size={20} /> +49 (0) 30 12345678 (HQ)
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </section>
            </main>

            <Footer />
        </div>
    );
}
