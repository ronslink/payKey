import { ShieldCheck, Menu, X } from 'lucide-react';
import { useState } from 'react';

export function Header() {
    const [isMenuOpen, setIsMenuOpen] = useState(false);

    return (
        <header className="fixed top-0 left-0 right-0 z-50 bg-opacity-80 backdrop-blur-md border-b border-gray-800 bg-[#020617]/80">
            <div className="container" style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', height: '80px' }}>

                {/* Logo */}
                <a href="/" style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                    <div style={{ background: 'linear-gradient(135deg, #3b82f6 0%, #2563eb 100%)', padding: '8px', borderRadius: '12px' }}>
                        <ShieldCheck size={24} color="white" />
                    </div>
                    <div>
                        <h1 style={{ fontSize: '1.25rem', fontWeight: '800', letterSpacing: '-0.025em' }}>Paydome</h1>
                        <p style={{ fontSize: '0.75rem', color: '#94a3b8' }}>by PayGlobus</p>
                    </div>
                </a>

                {/* Desktop Nav */}
                <nav className="hidden-mobile" style={{ display: 'flex', gap: '2rem' }}>
                    <a href="/" style={{ fontSize: '0.95rem', fontWeight: '500', color: '#f8fafc' }}>Home</a>
                    <a href="/help" style={{ fontSize: '0.95rem', fontWeight: '500', color: '#94a3b8' }}>iOS Help</a>
                </nav>

                {/* Mobile Menu Toggle */}
                <button
                    className="mobile-only"
                    onClick={() => setIsMenuOpen(!isMenuOpen)}
                    style={{ background: 'transparent', border: 'none', color: 'white', cursor: 'pointer', display: 'none' }}
                >
                    {isMenuOpen ? <X /> : <Menu />}
                </button>
            </div>
        </header>
    );
}
