import { useState, useEffect } from 'react'

const loadingPhrases = [
  'Connecting to M-Pesa',
  'Loading KRA compliance',
  'Securing your payroll',
  'Preparing your dashboard',
]

export default function LoadingScreen({ onComplete }: { onComplete: () => void }) {
  const [progress, setProgress] = useState(0)
  const [currentPhrase, setCurrentPhrase] = useState(0)
  const [fadeOut, setFadeOut] = useState(false)

  useEffect(() => {
    // Progress bar animation
    const progressInterval = setInterval(() => {
      setProgress(prev => {
        if (prev >= 100) {
          clearInterval(progressInterval)
          return 100
        }
        // Accelerate towards end
        const increment = prev < 60 ? 2 : prev < 85 ? 3 : 5
        return Math.min(prev + increment, 100)
      })
    }, 40)

    // Phrase rotation
    const phraseInterval = setInterval(() => {
      setCurrentPhrase(prev => (prev + 1) % loadingPhrases.length)
    }, 600)

    return () => {
      clearInterval(progressInterval)
      clearInterval(phraseInterval)
    }
  }, [])

  useEffect(() => {
    if (progress >= 100) {
      const timeout = setTimeout(() => setFadeOut(true), 300)
      const completeTimeout = setTimeout(() => onComplete(), 900)
      return () => {
        clearTimeout(timeout)
        clearTimeout(completeTimeout)
      }
    }
  }, [progress, onComplete])

  return (
    <div
      className={`fixed inset-0 z-[9999] flex flex-col items-center justify-center bg-[#070B14] transition-opacity duration-600 ${
        fadeOut ? 'opacity-0 pointer-events-none' : 'opacity-100'
      }`}
    >
      {/* Animated Ring Background */}
      <div className="relative w-40 h-40 mb-10">
        {/* Outer ring */}
        <div className="absolute inset-0 rounded-full border-2 border-dashed border-emerald-500/20 animate-[spin_12s_linear_infinite]" />
        {/* Middle ring */}
        <div className="absolute inset-3 rounded-full border border-dashed border-emerald-500/30 animate-[spin_8s_linear_infinite_reverse]" />
        {/* Inner ring */}
        <div className="absolute inset-6 rounded-full border border-emerald-500/15 animate-[spin_15s_linear_infinite]" />
        {/* Glow pulse */}
        <div className="absolute inset-8 rounded-full bg-emerald-500/10 animate-pulse" />
        {/* Center Logo */}
        <div className="absolute inset-0 flex items-center justify-center">
          <div className="w-16 h-16 rounded-2xl overflow-hidden shadow-xl shadow-orange-500/30 animate-[pulse_2s_ease-in-out_infinite]">
            <img src="/app-icon.jpg" alt="Paydome" className="w-full h-full object-cover" />
          </div>
        </div>
      </div>

      {/* Brand */}
      <h1 className="text-2xl font-bold text-white tracking-tight mb-1">Paydome</h1>
      <p className="text-xs text-slate-500 tracking-widest uppercase mb-10">Domestic Payroll · Kenya</p>

      {/* Loading phrase */}
      <p className="text-sm text-emerald-400/80 font-mono mb-6 h-5 transition-all duration-300">
        {loadingPhrases[currentPhrase]}...
      </p>

      {/* Progress bar */}
      <div className="w-64 h-1 bg-white/5 rounded-full overflow-hidden">
        <div
          className="h-full bg-gradient-to-r from-emerald-500 to-emerald-400 rounded-full transition-all duration-100 ease-out shadow-[0_0_12px_rgba(16,185,129,0.4)]"
          style={{ width: `${progress}%` }}
        />
      </div>
      <p className="text-[11px] text-slate-600 mt-3 font-mono">{progress}%</p>

      {/* Feature badges */}
      <div className="flex items-center gap-4 mt-10">
        {['M-Pesa Native', 'KRA · NHIF · SHIF', 'AES-256 Encrypted'].map((badge) => (
          <span
            key={badge}
            className="text-[10px] text-slate-500 px-3 py-1 rounded-full border border-white/5 bg-white/[0.02]"
          >
            {badge}
          </span>
        ))}
      </div>
    </div>
  )
}
