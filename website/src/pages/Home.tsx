import React from 'react';
import { Header } from '../components/Header';
import { Footer } from '../components/Footer';
import { ArrowRight, Shield, Globe, Smartphone } from 'lucide-react';

export default function Home() {
    return (
        <div style={{ minHeight: '100vh', display: 'flex', flexDirection: 'column' }}>
            <Header />

            <main style={{ flex: 1 }}>
                {/* Hero Section */}
                <section style={{ paddingTop: '160px', paddingBottom: '100px', textAlign: 'center', position: 'relative', overflow: 'hidden' }}>
                    <div style={{ position: 'absolute', top: '50%', left: '50%', transform: 'translate(-50%, -50%)', width: '600px', height: '600px', background: 'radial-gradient(circle, rgba(59,130,246,0.15) 0%, rgba(2,6,23,0) 70%)', zIndex: -1 }}></div>

                    <div className="container">
                        <div style={{ display: 'inline-block', padding: '0.5rem 1rem', borderRadius: '999px', background: 'rgba(59, 130, 246, 0.1)', color: '#60a5fa', marginBottom: '1.5rem', fontSize: '0.875rem', fontWeight: 600 }}>
                            🚀 Backed by PayGlobus Germany
                        </div>

                        <h1 style={{ fontSize: 'clamp(2.5rem, 5vw, 4.5rem)', fontWeight: 800, lineHeight: 1.1, marginBottom: '1.5rem' }}>
                            Payroll Simplified. <br />
                            <span className="text-gradient">Globally Trusted.</span>
                        </h1>

                        <p style={{ fontSize: '1.25rem', color: '#94a3b8', maxWidth: '600px', margin: '0 auto 2.5rem' }}>
                            Manage your workforce with the precision of German engineering. Secure, automated, and effortless payroll for the modern era.
                        </p>

                        <div style={{ display: 'flex', gap: '1rem', justifyContent: 'center' }}>
                            <button className="btn btn-primary">
                                Get Started <ArrowRight size={18} style={{ marginLeft: '0.5rem' }} />
                            </button>
                            <button className="btn" style={{ background: '#1e293b', color: 'white' }}>
                                View Demo
                            </button>
                        </div>
                    </div>
                </section>

                {/* Features Grid */}
                <section className="section" style={{ background: '#0f172a' }}>
                    <div className="container">
                        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(300px, 1fr))', gap: '2rem' }}>

                            <FeatureCard
                                icon={<Shield size={32} className="text-blue-500" />}
                                title="Bank-Grade Security"
                                description="Your data is protected by enterprise-level encryption and strict compliance standards."
                            />

                            <FeatureCard
                                icon={<Globe size={32} className="text-blue-500" />}
                                title="Global Compliance"
                                description="Navigate international tax laws effortlessly with our PayGlobus regulatory engine."
                            />

                            <FeatureCard
                                icon={<Smartphone size={32} className="text-blue-500" />}
                                title="Mobile First"
                                description="Manage payroll on the go with our award-winning iOS and Android applications."
                            />

                        </div>
                    </div>
                </section>

                {/* Social Proof / Trust */}
                <section className="section">
                    <div className="container" style={{ textAlign: 'center' }}>
                        <h2 style={{ fontSize: '2rem', marginBottom: '3rem' }}>Trusted by industry leaders</h2>
                        <div style={{ display: 'flex', flexWrap: 'wrap', justifyContent: 'center', gap: '4rem', opacity: 0.5, filter: 'grayscale(100%)' }}>
                            {/* Placeholders for logos (Text for now) */}
                            <h3 style={{ fontSize: '1.5rem', fontWeight: 700 }}>TechCorp</h3>
                            <h3 style={{ fontSize: '1.5rem', fontWeight: 700 }}>GlobalSystems</h3>
                            <h3 style={{ fontSize: '1.5rem', fontWeight: 700 }}>InnovateAG</h3>
                            <h3 style={{ fontSize: '1.5rem', fontWeight: 700 }}>FutureWork</h3>
                        </div>
                    </div>
                </section>

                {/* CTA */}
                <section className="section">
                    <div className="container">
                        <div style={{ background: 'linear-gradient(135deg, #1e40af 0%, #172554 100%)', borderRadius: '24px', padding: '4rem', textAlign: 'center' }}>
                            <h2 style={{ fontSize: '2.5rem', marginBottom: '1rem' }}>Ready to modernize your payroll?</h2>
                            <p style={{ color: '#bfdbfe', marginBottom: '2rem', fontSize: '1.1rem' }}>Join thousands of companies using Paydome to streamline their operations.</p>
                            <button className="btn" style={{ background: 'white', color: '#1e3a8a' }}>
                                Start Free Trial
                            </button>
                        </div>
                    </div>
                </section>
            </main>

            <Footer />
        </div>
    );
}

function FeatureCard({ icon, title, description }: { icon: React.ReactNode, title: string, description: string }) {
    return (
        <div style={{ padding: '2rem', background: '#020617', borderRadius: '16px', border: '1px solid #1e293b' }}>
            <div style={{ marginBottom: '1rem' }}>{icon}</div>
            <h3 style={{ fontSize: '1.25rem', marginBottom: '0.5rem', fontWeight: 600 }}>{title}</h3>
            <p style={{ color: '#94a3b8' }}>{description}</p>
        </div>
    );
}
