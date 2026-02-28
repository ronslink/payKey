import { Globe, Shield, Lock } from 'lucide-react';
import { Link } from 'react-router-dom';

export function Footer() {
    const currentYear = new Date().getFullYear();

    return (
        <footer style={{ borderTop: '1px solid var(--border)', padding: '4rem 0', background: 'var(--dark-bg)' }}>
            <div className="container">
                <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', textAlign: 'center', gap: '2rem' }}>

                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', color: 'var(--dark-muted)' }}>
                        <Globe size={20} />
                        <span style={{ fontWeight: 600 }}>PayGlobus Group</span>
                    </div>

                    <div style={{ maxWidth: '600px', margin: '0 auto', color: 'var(--dark-muted)', fontSize: '0.9375rem' }}>
                        <p>Paydome is a wholly owned subsidiary of PayGlobus GmbH. Bringing German engineering precision to global payroll solutions.</p>
                    </div>

                    <div style={{ display: 'flex', gap: '2rem', marginTop: '1rem', fontSize: '0.875rem', color: 'var(--dark-muted)' }}>
                        <Link to="/paydome/privacy_policy" style={{ transition: 'color 150ms ease' }}>Privacy Policy</Link>
                        <a href="#" style={{ transition: 'color 150ms ease' }}>Terms of Service</a>
                        <a href="/help" style={{ transition: 'color 150ms ease' }}>Contact Support</a>
                    </div>

                    <div style={{ display: 'flex', gap: '1.5rem', marginTop: '0.5rem', fontSize: '0.8125rem', color: 'oklch(0.5 0 0)' }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '0.375rem' }}>
                            <Shield className="w-4 h-4" style={{ color: 'var(--success)' }} />
                            <span>SOC 2</span>
                        </div>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '0.375rem' }}>
                            <Lock className="w-4 h-4" style={{ color: 'var(--success)' }} />
                            <span>GDPR</span>
                        </div>
                    </div>

                    <div style={{ fontSize: '0.875rem', color: 'oklch(0.4 0 0)' }}>
                        © {currentYear} Paydome / PayGlobus GmbH. All rights reserved.
                    </div>
                </div>
            </div>
        </footer>
    );
}
