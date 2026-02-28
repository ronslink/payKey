import React from 'react';
import { Header } from '../components/Header';
import { Footer } from '../components/Footer';
import { VideoSection } from '../components/VideoSection';
import { ArrowRight, Shield, Globe, Smartphone, Sparkles } from 'lucide-react';

export default function Home() {
    return (
        <div style={{ minHeight: '100vh', display: 'flex', flexDirection: 'column' }}>
            <Header />

            <main style={{ flex: 1 }}>
                {/* Hero Section */}
                <section className="hero-gradient" style={{ paddingTop: '160px', paddingBottom: '100px', textAlign: 'center', position: 'relative', overflow: 'hidden' }}>
                    <div className="container">
                        <div className="badge">
                            <Sparkles className="w-4 h-4" style={{ marginRight: '0.5rem' }} />
                            Backed by PayGlobus Germany
                        </div>

                        <h1 style={{ fontSize: 'clamp(2.5rem, 5vw, 4rem)', fontWeight: 800, lineHeight: 1.1, marginBottom: '1.5rem' }}>
                            Payroll Simplified. <br />
                            <span className="text-gradient">Globally Trusted.</span>
                        </h1>

                        <p className="text-muted" style={{ fontSize: '1.25rem', maxWidth: '600px', margin: '0 auto 2.5rem' }}>
                            Manage your workforce with the precision of German engineering. Secure, automated, and effortless payroll for the modern era.
                        </p>

                        <div style={{ display: 'flex', gap: '1rem', justifyContent: 'center', flexWrap: 'wrap' }}>
                            <button className="btn btn-primary">
                                Get Started <ArrowRight size={18} style={{ marginLeft: '0.5rem' }} />
                            </button>
                            <button
                                className="btn btn-secondary"
                                onClick={() => {
                                    document.getElementById('video-section')?.scrollIntoView({
                                        behavior: 'smooth',
                                        block: 'center'
                                    });
                                }}
                            >
                                View Demo
                            </button>
                        </div>
                    </div>
                </section>

                {/* Video Section */}
                <div id="video-section">
                    <VideoSection />
                </div>

                {/* Features Grid */}
                <section className="section" style={{ background: 'var(--dark-bg)' }}>
                    <div className="container">
                        <div className="grid-auto stagger-children">

                            <FeatureCard
                                icon={<Shield size={32} />}
                                title="Bank-Grade Security"
                                description="Your data is protected by enterprise-level encryption and strict compliance standards."
                            />

                            <FeatureCard
                                icon={<Globe size={32} />}
                                title="Global Compliance"
                                description="Navigate international tax laws effortlessly with our PayGlobus regulatory engine."
                            />

                            <FeatureCard
                                icon={<Smartphone size={32} />}
                                title="Mobile First"
                                description="Manage payroll on the go with our award-winning iOS and Android applications."
                            />

                        </div>
                    </div>
                </section>

                {/* Social Proof / Trust */}
                <section className="section" style={{ background: 'var(--dark-surface)' }}>
                    <div className="container" style={{ textAlign: 'center' }}>
                        <h2 style={{ fontSize: '2rem', marginBottom: '3rem', fontWeight: 600 }}>Trusted by industry leaders</h2>
                        <div className="trust-logos">
                            <span className="trust-logo">TechCorp</span>
                            <span className="trust-logo">GlobalSystems</span>
                            <span className="trust-logo">InnovateAG</span>
                            <span className="trust-logo">FutureWork</span>
                        </div>
                    </div>
                </section>

                {/* CTA */}
                <section className="section">
                    <div className="container">
                        <div className="cta-gradient">
                            <h2 style={{ fontSize: '2.5rem', marginBottom: '1rem', fontWeight: 700 }}>Ready to modernize your payroll?</h2>
                            <p style={{ color: 'rgba(255,255,255,0.8)', marginBottom: '2rem', fontSize: '1.1rem' }}>Join thousands of companies using Paydome to streamline their operations.</p>
                            <button className="btn btn-primary" style={{ background: 'white', color: 'oklch(0.2 0.15 265)' }}>
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
        <div className="card-feature">
            <div className="feature-icon">{icon}</div>
            <h3 style={{ fontSize: '1.25rem', marginBottom: '0.5rem', fontWeight: 600 }}>{title}</h3>
            <p className="text-muted">{description}</p>
        </div>
    );
}
