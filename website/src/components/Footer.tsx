import { Globe } from 'lucide-react';
import { Link } from 'react-router-dom';

export function Footer() {
    return (
        <footer style={{ borderTop: '1px solid #1e293b', padding: '4rem 0', background: '#020617' }}>
            <div className="container">
                <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', textAlign: 'center', gap: '2rem' }}>

                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', color: '#94a3b8' }}>
                        <Globe size={20} />
                        <span style={{ fontWeight: 600 }}>PayGlobus Group</span>
                    </div>

                    <div style={{ maxWidth: '600px', margin: '0 auto', color: '#64748b' }}>
                        <p>Paydome is a wholly owned subsidiary of PayGlobus GmbH. Bringing German engineering precision to global payroll solutions.</p>
                    </div>

                    <div style={{ display: 'flex', gap: '2rem', marginTop: '1rem', fontSize: '0.875rem', color: '#64748b' }}>
                        <Link to="/paydome/privacy_policy">Privacy Policy</Link>
                        <a href="#">Terms of Service</a>
                        <a href="/help">Contact Support</a>
                    </div>

                    <div style={{ fontSize: '0.875rem', color: '#475569' }}>
                        © {new Date().getFullYear()} Paydome / PayGlobus GmbH. All rights reserved.
                    </div>
                </div>
            </div>
        </footer>
    );
}
