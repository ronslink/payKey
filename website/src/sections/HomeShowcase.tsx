import { Check, ArrowRight } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Link } from 'react-router-dom'

const highlights = [
  'Send salary via M-Pesa in seconds',
  'Auto SHIF, NSSF & PAYE deductions',
  'KRA-compliant payslips via SMS/WhatsApp',
  'Scheduled recurring payments',
  'Payment reminders so you never forget',
  'Complete records for tax season',
]

export default function HomeShowcase() {
  return (
    <section className="relative py-24 overflow-hidden">
      <div className="absolute top-1/2 right-0 w-[500px] h-[500px] bg-emerald-500/5 rounded-full blur-[120px] pointer-events-none -translate-y-1/2" />
      
      <div className="relative max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="grid lg:grid-cols-2 gap-12 lg:gap-16 items-center">
          {/* Left - User guide video */}
          <div className="relative order-2 lg:order-1">
            <div className="absolute -inset-5 bg-gradient-to-r from-emerald-500/15 via-cyan-500/10 to-violet-500/15 rounded-2xl blur-2xl" />
            <div className="relative rounded-2xl border border-white/10 bg-white/[0.03] p-3 shadow-2xl overflow-hidden">
              <video
                className="block w-full rounded-xl bg-slate-950"
                controls
                preload="metadata"
                poster="/payroll-management-screen.png"
              >
                <source src="/paydome-payroll-user-guide.mp4" type="video/mp4" />
              </video>
            </div>
            {/* Floating notification */}
            <div className="absolute -bottom-4 -right-2 sm:-right-4 bg-[#0D1525]/95 backdrop-blur-xl border border-emerald-500/20 rounded-xl p-4 shadow-xl">
              <div className="flex items-center gap-2">
                <div className="w-8 h-8 rounded-full bg-emerald-500/20 flex items-center justify-center">
                  <Check className="w-4 h-4 text-emerald-400" />
                </div>
                <div>
                  <div className="text-sm font-semibold text-white">User guide included</div>
                  <div className="text-xs text-slate-400">Watch payroll setup step by step</div>
                </div>
              </div>
            </div>
          </div>

          {/* Right - Content */}
          <div className="order-1 lg:order-2">
            <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 text-xs font-medium mb-6">
              How It Works
            </div>
            <h2 className="text-3xl sm:text-4xl font-bold text-white mb-6 leading-tight">
              Pay your house help,{' '}
              <span className="text-gradient">gardener & driver</span> with ease
            </h2>
            <p className="text-lg text-slate-400 mb-8 leading-relaxed">
              Whether you have one worker or a full household staff, Paydome makes paying salaries 
              simple, professional, and compliant. Your staff gets paid on time, every time — 
              straight to their M-Pesa.
            </p>

            {/* Highlights */}
            <div className="space-y-3 mb-8">
              {highlights.map((item) => (
                <div key={item} className="flex items-center gap-3">
                  <div className="w-5 h-5 rounded-full bg-emerald-500/20 flex items-center justify-center shrink-0">
                    <Check className="w-3 h-3 text-emerald-400" />
                  </div>
                  <span className="text-sm text-slate-300">{item}</span>
                </div>
              ))}
            </div>

            <Link to="/features">
              <Button className="bg-emerald-500 hover:bg-emerald-600 text-white font-semibold shadow-lg shadow-emerald-500/20">
                See All Features
                <ArrowRight className="w-4 h-4 ml-2" />
              </Button>
            </Link>
          </div>
        </div>
      </div>
    </section>
  )
}
