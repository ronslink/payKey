import { useState } from 'react';
import { Play, Video, Target, Lightbulb, Zap } from 'lucide-react';

export function VideoSection() {
    const [isPlaying, setIsPlaying] = useState(false);

    return (
        <section className="section" style={{ background: 'var(--dark-bg)' }}>
            <div className="container">
                <div style={{ textAlign: 'center', marginBottom: '3rem' }}>
                    <div className="badge">
                        <Video className="w-4 h-4" style={{ marginRight: '0.5rem' }} />
                        See It In Action
                    </div>
                    <h2 style={{ fontSize: '2.5rem', fontWeight: 700, marginBottom: '1rem' }}>
                        Watch Paydome <span className="text-gradient">Simplify Payroll</span>
                    </h2>
                    <p style={{ fontSize: '1.1rem', color: 'var(--dark-muted)', maxWidth: '700px', margin: '0 auto' }}>
                        Discover how Paydome makes managing domestic workers effortless—from M-Pesa payments to tax compliance.
                    </p>
                </div>

                <div style={{ maxWidth: '900px', margin: '0 auto', position: 'relative' }}>
                    {/* Video Container */}
                    <div style={{
                        position: 'relative',
                        paddingBottom: '56.25%',
                        borderRadius: '16px',
                        overflow: 'hidden',
                        boxShadow: '0 20px 60px oklch(0.55 0.2 265 / 0.2)',
                        background: 'var(--dark-surface)'
                    }}>
                        {isPlaying ? (
                            <img
                                src="/explainer.webp"
                                alt="Paydome Walkthrough Demo"
                                style={{
                                    position: 'absolute',
                                    top: 0,
                                    left: 0,
                                    width: '100%',
                                    height: '100%',
                                    objectFit: 'cover',
                                    cursor: 'pointer'
                                }}
                                onClick={() => setIsPlaying(false)}
                                title="Click to pause"
                            />
                        ) : (
                            <img
                                src="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='1920' height='1080'%3E%3Crect width='1920' height='1080' fill='%230f172a'/%3E%3Ctext x='50%25' y='50%25' dominant-baseline='middle' text-anchor='middle' font-family='Arial' font-size='48' fill='%2394a3b8'%3EPaydome Explainer Video%3C/text%3E%3C/svg%3E"
                                alt="Video Poster"
                                style={{
                                    position: 'absolute',
                                    top: 0,
                                    left: 0,
                                    width: '100%',
                                    height: '100%',
                                    objectFit: 'cover'
                                }}
                            />
                        )}

                        {/* Custom Play Button Overlay (shows when paused) */}
                        {!isPlaying && (
                            <button
                                onClick={() => setIsPlaying(true)}
                                style={{
                                    position: 'absolute',
                                    top: '50%',
                                    left: '50%',
                                    transform: 'translate(-50%, -50%)',
                                    width: '80px',
                                    height: '80px',
                                    borderRadius: '50%',
                                    background: 'oklch(0.55 0.2 265)',
                                    border: 'none',
                                    cursor: 'pointer',
                                    display: 'flex',
                                    alignItems: 'center',
                                    justifyContent: 'center',
                                    transition: 'all 150ms ease',
                                    boxShadow: '0 8px 24px oklch(0.55 0.2 265 / 0.4)'
                                }}
                                onMouseEnter={(e) => {
                                    e.currentTarget.style.transform = 'translate(-50%, -50%) scale(1.1)';
                                }}
                                onMouseLeave={(e) => {
                                    e.currentTarget.style.transform = 'translate(-50%, -50%) scale(1)';
                                }}
                            >
                                <Play size={32} color="white" fill="white" style={{ marginLeft: '4px' }} />
                            </button>
                        )}
                    </div>

                    {/* Video Features */}
                    <div style={{
                        display: 'grid',
                        gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))',
                        gap: '1.5rem',
                        marginTop: '2rem'
                    }}>
                        <VideoFeature
                            icon={<Zap size={24} />}
                            title="60 Seconds"
                            description="Quick overview of all features"
                        />
                        <VideoFeature
                            icon={<Target size={24} />}
                            title="Real Demo"
                            description="See the actual app in action"
                        />
                        <VideoFeature
                            icon={<Lightbulb size={24} />}
                            title="Easy to Follow"
                            description="Clear, step-by-step walkthrough"
                        />
                    </div>
                </div>
            </div>
        </section>
    );
}

function VideoFeature({ icon, title, description }: { icon: React.ReactNode; title: string; description: string }) {
    return (
        <div className="card-feature" style={{ textAlign: 'center', padding: '1.5rem' }}>
            <div style={{ fontSize: '1.5rem', marginBottom: '0.75rem', color: 'var(--dark-primary)' }}>{icon}</div>
            <h4 style={{ fontSize: '1rem', fontWeight: 600, marginBottom: '0.25rem' }}>{title}</h4>
            <p style={{ fontSize: '0.875rem', color: 'var(--dark-muted)', margin: 0 }}>{description}</p>
        </div>
    );
}
