import { useRef, useState } from 'react';
import { Play } from 'lucide-react';

export function VideoSection() {
    const videoRef = useRef<HTMLVideoElement>(null);
    const [isPlaying, setIsPlaying] = useState(false);

    const togglePlay = () => {
        if (videoRef.current) {
            if (isPlaying) {
                videoRef.current.pause();
            } else {
                videoRef.current.play();
            }
            setIsPlaying(!isPlaying);
        }
    };

    return (
        <section className="section" style={{ background: '#020617' }}>
            <div className="container">
                <div style={{ textAlign: 'center', marginBottom: '3rem' }}>
                    <div style={{ display: 'inline-block', padding: '0.5rem 1rem', borderRadius: '999px', background: 'rgba(59, 130, 246, 0.1)', color: '#60a5fa', marginBottom: '1rem', fontSize: '0.875rem', fontWeight: 600 }}>
                        📹 See It In Action
                    </div>
                    <h2 style={{ fontSize: '2.5rem', fontWeight: 700, marginBottom: '1rem' }}>
                        Watch Paydome <span className="text-gradient">Simplify Payroll</span>
                    </h2>
                    <p style={{ fontSize: '1.1rem', color: '#94a3b8', maxWidth: '700px', margin: '0 auto' }}>
                        Discover how Paydome makes managing domestic workers effortless—from M-Pesa payments to tax compliance.
                    </p>
                </div>

                <div style={{ maxWidth: '900px', margin: '0 auto', position: 'relative' }}>
                    {/* Video Container */}
                    <div style={{
                        position: 'relative',
                        paddingBottom: '56.25%', /* 16:9 aspect ratio */
                        borderRadius: '16px',
                        overflow: 'hidden',
                        boxShadow: '0 20px 60px rgba(59, 130, 246, 0.3)',
                        background: '#0f172a'
                    }}>
                        <video
                            ref={videoRef}
                            style={{
                                position: 'absolute',
                                top: 0,
                                left: 0,
                                width: '100%',
                                height: '100%',
                                objectFit: 'cover'
                            }}
                            controls
                            poster="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='1920' height='1080'%3E%3Crect width='1920' height='1080' fill='%230f172a'/%3E%3Ctext x='50%25' y='50%25' dominant-baseline='middle' text-anchor='middle' font-family='Arial' font-size='48' fill='%2394a3b8'%3EPaydome Explainer Video%3C/text%3E%3C/svg%3E"
                            onPlay={() => setIsPlaying(true)}
                            onPause={() => setIsPlaying(false)}
                        >
                            {/* Placeholder video - replace with actual Paydome explainer video */}
                            <source src="https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4" type="video/mp4" />
                            Your browser does not support the video tag.
                        </video>

                        {/* Custom Play Button Overlay (shows when paused) */}
                        {!isPlaying && (
                            <button
                                onClick={togglePlay}
                                style={{
                                    position: 'absolute',
                                    top: '50%',
                                    left: '50%',
                                    transform: 'translate(-50%, -50%)',
                                    width: '80px',
                                    height: '80px',
                                    borderRadius: '50%',
                                    background: 'rgba(59, 130, 246, 0.9)',
                                    border: 'none',
                                    cursor: 'pointer',
                                    display: 'flex',
                                    alignItems: 'center',
                                    justifyContent: 'center',
                                    transition: 'all 0.3s ease',
                                    boxShadow: '0 8px 24px rgba(59, 130, 246, 0.4)'
                                }}
                                onMouseEnter={(e) => {
                                    e.currentTarget.style.transform = 'translate(-50%, -50%) scale(1.1)';
                                    e.currentTarget.style.background = 'rgba(59, 130, 246, 1)';
                                }}
                                onMouseLeave={(e) => {
                                    e.currentTarget.style.transform = 'translate(-50%, -50%) scale(1)';
                                    e.currentTarget.style.background = 'rgba(59, 130, 246, 0.9)';
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
                            icon="⚡"
                            title="60 Seconds"
                            description="Quick overview of all features"
                        />
                        <VideoFeature
                            icon="🎯"
                            title="Real Demo"
                            description="See the actual app in action"
                        />
                        <VideoFeature
                            icon="💡"
                            title="Easy to Follow"
                            description="Clear, step-by-step walkthrough"
                        />
                    </div>
                </div>
            </div>
        </section>
    );
}

function VideoFeature({ icon, title, description }: { icon: string; title: string; description: string }) {
    return (
        <div style={{
            textAlign: 'center',
            padding: '1.5rem',
            background: '#0f172a',
            borderRadius: '12px',
            border: '1px solid #1e293b'
        }}>
            <div style={{ fontSize: '2rem', marginBottom: '0.5rem' }}>{icon}</div>
            <h4 style={{ fontSize: '1rem', fontWeight: 600, marginBottom: '0.25rem', color: 'white' }}>{title}</h4>
            <p style={{ fontSize: '0.875rem', color: '#94a3b8', margin: 0 }}>{description}</p>
        </div>
    );
}
