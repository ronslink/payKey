import { ArrowRight, Play, Sparkles, Smartphone } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Link } from 'react-router-dom'
import { useEffect, useState, useRef } from 'react'

export default function HomeHero() {
  const [visible, setVisible] = useState(false)
  const sectionRef = useRef<HTMLElement>(null)

  useEffect(() => {
    const timer = setTimeout(() => setVisible(true), 200)
    return () => clearTimeout(timer)
  }, [])

  return (
    <section ref={sectionRef} className="relative overflow-hidden">
      {/* Background */}
      <div className="absolute inset-0 bg-gradient-to-b from-emerald-500/5 via-transparent to-transparent" />
      <div className="absolute top-1/4 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[600px] h-[600px] bg-emerald-500/8 rounded-full blur-[120px] pointer-events-none" />
      
      <div className="relative max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 pt-16 sm:pt-24 lg:pt-32 pb-8">
        <div className="flex flex-col items-center text-center">
          {/* Badge */}
          <div className={`inline-flex items-center gap-2 px-4 py-2 rounded-full bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 text-sm font-medium mb-8 transition-all duration-700 ${visible ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-4'}`}>
            <Sparkles className="w-4 h-4" />
            Made for Kenya · M-Pesa Native
          </div>

          {/* Headline */}
          <h1 className={`text-4xl sm:text-5xl lg:text-7xl font-bold tracking-tight text-white mb-6 leading-[1.08] transition-all duration-700 delay-100 ${visible ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-6'}`}>
            Pay your help,{' '}
            <span className="text-gradient italic">simply</span>.
            <br />
            Right from your{' '}
            <span className="text-gradient italic">phone</span>.
          </h1>

          {/* Subtitle */}
          <p className={`text-lg sm:text-xl text-slate-400 max-w-2xl mb-10 leading-relaxed transition-all duration-700 delay-200 ${visible ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-6'}`}>
            Manage your house help, driver, nanny, or gardener like a pro. M-Pesa
            payments, KRA-ready payslips, NHIF and SHIF auto-calculated — all
            from one app.
          </p>

          {/* CTAs */}
          <div className={`flex flex-col sm:flex-row items-center gap-4 mb-8 transition-all duration-700 delay-300 ${visible ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-6'}`}>
            <Link to="/pricing">
              <Button
                size="lg"
                className="bg-emerald-500 hover:bg-emerald-600 text-white font-semibold px-8 shadow-xl shadow-emerald-500/25 transition-all hover:shadow-emerald-500/40 hover:scale-[1.02]"
              >
                Get the app
                <ArrowRight className="w-4 h-4 ml-2" />
              </Button>
            </Link>
            <Link to="/features">
              <Button
                size="lg"
                variant="outline"
                className="border-white/10 bg-white/5 hover:bg-white/10 text-white font-semibold px-8 backdrop-blur-sm"
              >
                <Play className="w-4 h-4 mr-2" />
                See how it works
              </Button>
            </Link>
          </div>

          {/* Trust badges */}
          <div className={`flex items-center gap-6 mb-16 transition-all duration-700 delay-[400ms] ${visible ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-4'}`}>
            {[
              { icon: '💰', label: 'M-Pesa native' },
              { icon: '📄', label: 'KRA · NHIF · SHIF' },
              { icon: '✨', label: 'Setup in 5 minutes' },
            ].map(({ icon, label }) => (
              <span key={label} className="flex items-center gap-1.5 text-xs text-slate-400">
                <span>{icon}</span> {label}
              </span>
            ))}
          </div>

          {/* 3D App Screenshots */}
          <div className={`relative w-full max-w-5xl transition-all duration-1000 delay-500 ${visible ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-12'}`}>
            {/* Ambient glow */}
            <div className="absolute inset-x-12 -bottom-12 h-64 bg-emerald-500/10 rounded-full blur-[80px] pointer-events-none" />
            
            {/* Screenshots container */}
            <div className="relative flex items-end justify-center gap-0 sm:gap-0 h-[400px] sm:h-[500px] lg:h-[600px]">
              {/* Left phone - Workforce screen */}
              <div className="absolute left-[5%] sm:left-[10%] bottom-0 z-10 w-[35%] sm:w-[30%] max-w-[260px] transform -rotate-6 origin-bottom translate-y-4 hover:translate-y-0 hover:-rotate-3 transition-all duration-500">
                <div className="relative rounded-[24px] sm:rounded-[32px] overflow-hidden border-2 border-white/10 shadow-2xl shadow-black/50 bg-[#0D1525]">
                  {/* Phone notch */}
                  <div className="absolute top-0 left-1/2 -translate-x-1/2 w-20 h-5 bg-black rounded-b-2xl z-10" />
                  <img
                    src="/mobile-mockup.jpg"
                    alt="Paydome Workforce Management Screen"
                    className="w-full h-auto"
                  />
                </div>
                {/* Badge */}
                <div className="absolute -top-3 -left-2 sm:-top-4 sm:-left-3 bg-[#0D1525]/95 backdrop-blur-xl border border-emerald-500/30 rounded-lg px-2 py-1 sm:px-3 sm:py-1.5 shadow-lg z-20">
                  <span className="text-[9px] sm:text-[10px] text-emerald-400 font-medium flex items-center gap-1">
                    <Smartphone className="w-2.5 h-2.5" /> My Workforce
                  </span>
                </div>
              </div>

              {/* Center phone - Dashboard (hero) */}
              <div className="relative z-20 w-[50%] sm:w-[40%] max-w-[320px] transform hover:scale-[1.02] transition-all duration-500">
                <div className="relative rounded-[28px] sm:rounded-[36px] overflow-hidden border-2 border-white/15 shadow-2xl shadow-emerald-500/10 bg-[#0D1525]">
                  {/* Phone notch */}
                  <div className="absolute top-0 left-1/2 -translate-x-1/2 w-24 h-6 bg-black rounded-b-2xl z-10" />
                  <img
                    src="/dashboard-mockup.jpg"
                    alt="Paydome Dashboard - Home Screen"
                    className="w-full h-auto"
                  />
                </div>
                {/* Floating stats */}
                <div className="absolute -bottom-5 left-1/2 -translate-x-1/2 bg-[#0D1525]/95 backdrop-blur-xl border border-white/10 rounded-xl px-4 py-2.5 shadow-xl z-30">
                  <div className="flex items-center gap-3 whitespace-nowrap">
                    <div>
                      <div className="text-[9px] text-slate-400">Paid This Month</div>
                      <div className="text-sm font-bold text-white">KES 4.2M+</div>
                    </div>
                    <div className="w-px h-8 bg-white/10" />
                    <div>
                      <div className="text-[9px] text-slate-400">Homes</div>
                      <div className="text-sm font-bold text-emerald-400">3,000+</div>
                    </div>
                  </div>
                </div>
              </div>

              {/* Right phone - Payment screen */}
              <div className="absolute right-[5%] sm:right-[10%] bottom-0 z-10 w-[35%] sm:w-[30%] max-w-[260px] transform rotate-6 origin-bottom translate-y-4 hover:translate-y-0 hover:rotate-3 transition-all duration-500">
                <div className="relative rounded-[24px] sm:rounded-[32px] overflow-hidden border-2 border-white/10 shadow-2xl shadow-black/50 bg-[#0D1525]">
                  {/* Phone notch */}
                  <div className="absolute top-0 left-1/2 -translate-x-1/2 w-20 h-5 bg-black rounded-b-2xl z-10" />
                  <img
                    src="/worker-payment.jpg"
                    alt="Paydome Worker Payment via M-Pesa"
                    className="w-full h-auto"
                  />
                </div>
                {/* Badge */}
                <div className="absolute -top-3 -right-2 sm:-top-4 sm:-right-3 bg-[#0D1525]/95 backdrop-blur-xl border border-emerald-500/30 rounded-lg px-2 py-1 sm:px-3 sm:py-1.5 shadow-lg z-20">
                  <span className="text-[9px] sm:text-[10px] text-emerald-400 font-medium">✓ KRA-registered</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Trust bar */}
      <div className="border-t border-white/5 bg-white/[0.02] mt-16">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-5 flex flex-col sm:flex-row items-center justify-between gap-4">
          <span className="text-xs text-slate-500 tracking-widest uppercase">
            Built for Kenya · KRA-Registered · M-Pesa Native
          </span>
          <div className="flex items-center gap-3">
            {['KRA · iTax', 'NHIF · SHIF', 'NSSF', 'M-Pesa API'].map((tag) => (
              <span
                key={tag}
                className="text-[10px] text-emerald-400/80 px-2.5 py-1 rounded-md border border-emerald-500/20 bg-emerald-500/5"
              >
                ✦ {tag}
              </span>
            ))}
          </div>
        </div>
      </div>
    </section>
  )
}
